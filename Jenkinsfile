// based on: https://github.com/snoopy3476/jenkins-pipeline-helper
/***** Demo Spring + Gradle cycle JenkinsFile *****/




/***************************************************
 *                                                 *
 *                [ Main Routine ]                 *
 *                                                 *
 ***************************************************/


/**
 *   Run example jenkins pipeline using helper
 */
void main () {
	podTemplate (podTemplateArgs()) { node ('jenkins-slave-pod') {





		// load scripts //
		checkout ([
			$class: 'GitSCM',
			userRemoteConfigs: [[
				url: 'http://192.168.7.83/common/jenkinspipeline.git', 
				credentialsId: 'GitLab-SCM'
			]],
			branches: [[name: '*/master']],
			extensions: [[
				$class: 'RelativeTargetDirectory',
				relativeTargetDir: '.jenkins'
			]],
		])
    
		def pipelineHelper = load ('.jenkins/modules/JenkinsPipelineHelper.groovy')
		def gitlabCallbacks = load ('.jenkins/modules/GitlabNotification.groovy')
		def slackCallbacks = load ('.jenkins/modules/SlackNotification.groovy')





		// set pipeline data //

		Map<String,Closure> pipelineData = pipelineData ()





		// set pipeline callbacks //

		List<Map> callbackMapList = [
			gitlabCallbacks(),
			slackCallbacks(),
			[
				pending: [
					{pipeline, stageIdx, stateList -> echo ("customCB - pending '${pipeline[stageIdx].stageName}'")},
					{pipeline, stageIdx, stateList -> echo ("customCB - another pending '${pipeline[stageIdx].stageName}'")},
				],
				running: {pipeline, stageIdx, stateList -> echo ("customCB - running '${pipeline[stageIdx].stageName}'")},
				passed: {pipeline, stageIdx, stateList -> echo ("customCB - passed '${pipeline[stageIdx].stageName}'")},
				failed: {pipeline, stageIdx, stateList -> echo ("customCB - failed '${pipeline[stageIdx].stageName}'")},
				aborted: {pipeline, stageIdx, stateList -> echo ("customCB - aborted '${pipeline[stageIdx].stageName}'")},
				canceled: {pipeline, stageIdx, stateList -> echo ("customCB - canceled '${pipeline[stageIdx].stageName}'")},
			],
		]

		Map<String,List<Closure>> callbackData = (
			['pending', 'running', 'passed', 'failed', 'aborted', 'canceled'].collectEntries { state ->
				[ (state): callbackMapList?.collect{ it?.get(state) }.flatten() ]
			}
		)





		// run pipeline //

		assert (
			slackCallbacks.runWithSlackMsgWrapper { // send slack msg before and after running inner closure

				// inner closure
				withEnv (stageEnv()) {
					pipelineHelper (pipelineData, callbackData)
				}

			}
		)





	} } // node, podTemplate
}





/***************************************************
 *                                                 *
 *             [ Config Environments ]             *
 *                                                 *
 ***************************************************/


/**
 *   Get base env vars
 *
 *       @return    Immutable List of env vars
 */
List stageEnv () { [

	// uid/gid
	HOST_UID: "${env.UID}",
	HOST_GID: "${env.GID}",

	// gradle config
	GRADLE_HOME_PATH: "${env.WORKSPACE}/.gradle", // path in containers
	GRADLE_LOCAL_CACHE_PATH: "/tmp/jenkins/.gradle", // path of host machine

	// docker private registry config
	PRIVATE_REG_URL: "http://10.0.1.250",
	PRIVATE_REG_PORT: "5000",
	DEPLOY_IMG_NAME: "${env.JOB_NAME}".toLowerCase(), // Job name should be docker-img-name-compatible
	DEPLOY_IMG_TAG: "build-${env.BUILD_NUMBER}",
	PRIVATE_REG_CRED_ID: "inner-private-registry-cred" // Jenkins credential

].collect {"${it.key}=${it.value}"} }


/**
 *   Get podTemplate args
 *
 *       @return    Immutable Map of podtemplate arguments
 */
Map podTemplateArgs () { [

	label: 'jenkins-slave-pod', 
	containers: [
		containerTemplate (
			name: 'build-container',
			image: 'openjdk:11',
			command: 'cat',
			ttyEnabled: true,
		),
		containerTemplate (
			name: 'push-container',
			image: 'docker',
			command: 'cat',
			ttyEnabled: true
		),
	],
	volumes: [ 
		// for docker
		hostPathVolume (mountPath: '/var/run/docker.sock',
				hostPath: '/var/run/docker.sock'), 
		// gradle home caching: mount local host path to 'env.GRADLE_HOME_PATH'
		hostPathVolume (mountPath: "${env.GRADLE_HOME_PATH}",
				hostPath: "${env.GRADLE_LOCAL_CACHE_PATH}"),
	],


].asImmutable() }





/***************************************************
 *                                                 *
 *                  [ Pipeline ]                   *
 *                                                 *
 ***************************************************/


/**
 *   Get pipeline data
 *
 *       @return    Map of [(stageName): (stageClosure)]
 */
Map<String,Closure> pipelineData () { [



/***** Checkout Stage *****/

	Checkout: {
		checkout (scm)
		checkout ([
			$class: 'GitSCM',
			userRemoteConfigs: [[
				url: "${env.gitlabSourceRepoHttpUrl}",
				credentialsId: 'GitLab-SCM'
			]],
			branches: [[name: '*/develop']],
		])
	},



/***** Build Stage *****/

	Build: {

		docker.image('openjdk:11').inside ("-u 0:0 -v $HOME/.gradle:${env.GRADLE_HOME_PATH}"){

			// parallel build
			parallel ([
				'[0] Main gradle build': {

					sh (
						label: 'Gradle Build',
						script: """
							./gradlew -g ${env.GRADLE_HOME_PATH} --parallel \\
								clean build --stacktrace -x test
						"""
					)

				},
			])

		}

		// archive built results
		archiveArtifacts (
			artifacts: 'build/libs/**/*.jar, build/libs/**/*.war',
			fingerprint: true
		)

	},



/***** Test Stage *****/

	Test: {
		try {
			docker.image('openjdk:11').inside ("-u 0:0 -v $HOME/.gradle:${env.GRADLE_HOME_PATH}") {
				sh (
					label: 'Gradle Parallel Test',
					script: """
						./gradlew -g ${env.GRADLE_HOME_PATH} --parallel \\
							test --stacktrace -x build
					"""
				)
			}

		} catch (e) {
			throw (e)
		} finally {

			// list of xml file list
			def junitXmlList =
				sh (
					label: 'Getting Junit Xml List',
					returnStdout: true,
					script: '''
							[ -d "build/test-results" ] \\
							&& find "build/test-results" \\
								-name "*.xml" \\
							|| true
						'''
				).readLines().sort()

			// list of parallel jobs
			def junitParallelSteps = [:]
			junitXmlList.eachWithIndex { String path, int idx ->

				// get file basename
				def posFrom = path.lastIndexOf ('/') + 1 // no occurence: 0
				def posTo = path.lastIndexOf ('.')
				def basename = path.substring (posFrom, posTo)

				junitParallelSteps << [ "[${idx}] ${basename}": {
						def res = junit (path)
						if (res.failCount == 0) {
							echo (
								"Test results of '${basename}': ["
								+ "Total ${res.totalCount}, "
								+ "Passed ${res.passCount}, "
								+ "Failed ${res.failCount}, "
								+ "Skipped ${res.skipCount}]"
							)
						} else {
							error ("Test failed: '${path}'")
						}

					} ]
			}

			// execute parallel junit jobs
			if (junitParallelSteps.size() > 0) {
				parallel (junitParallelSteps)
			}

		}

	},



/***** Push Stage *****/

	Push: {
		docker.image('docker:latest').inside {
			dockerImg = docker.build ("${env.DEPLOY_IMG_NAME}")
			docker.withRegistry ("${env.PRIVATE_REG_URL}:${env.PRIVATE_REG_PORT}",
				"${env.PRIVATE_REG_CRED_ID}") {
				dockerImg.push ("${env.DEPLOY_IMG_TAG}")
				dockerImg.push ()
			}
		}
	},




].asImmutable() }





// run main routine
main ()
