// based on: https://github.com/snoopy3476/jenkins-pipeline-helper
/***** Demo Spring + Gradle cycle JenkinsFile *****/


/***************************************************
 *          AVAILABLE JENKINS PARAMETERS           *
 *                                                 *
 *                                                 *
 * Set env var values below inside Jenkins project *
 * configuration, after checking the following     *
 * checkbox:     "This project is parameterized"   *
 ***************************************************/
/*************************************************** 
- REPO_CRED_ID
    ID of a Jenkins credential for a target repo you want to build
    - Type: String
    - Default: ""
- IMG_BUILDER_IMG_NAME
    Image to use when building a target repo
    - Type: String
    - Default: "openjdk:latest"
- IMG_TESTER_IMG_NAME
    Image to use when testing the built result of target repo
    - Type: String
    - Default: "openjdk:latest"
- IMG_DEPLOYER_IMG_NAME
    Image to use when deploying the built result to remote registry
    - Type: String
    - Default: "docker:latest"
- IMG_REGISTRY_URL
    Url of a remote registry to deploy built image
    - Type: String
    - Default: "http://127.0.0.1"
- IMG_REGISTRY_PORT
    Port of a remote registry to deploy built image
    - Type: String
    - Default: "5000"
- IMG_REGISTRY_CRED_ID
    ID of a Jenkins credential for a remote registry you want to deploy
    - Type: String
    - Default: ""
- IMG_NAME
    Name of an image you want inside a remote registry
    - Type: String
    - Default: "${env.gitlabSourceRepoName}".toLowerCase()
- IMG_TAG
    Tag of an image you want inside a remote registry
    - Type: String
    - Default: "build-${env.BUILD_NUMBER}_${commitHash}"
- IMG_IS_LATEST
    Current image is also set as 'latest' tag, in addition to IMG_TAG
    - Type: bool
    - Default: true
- SLACK_MSG_CH
    Channel of Slack to send notification
    - Type: String
    - Default: Slack plugin configuration default
 ***************************************************/








/***************************************************
 *                                                 *
 *                [ Main Routine ]                 *
 *                                                 *
 ***************************************************/


/**
 *   Run example jenkins pipeline using helper
 */
void main () {
	node {



		// load scripts //
		checkout (scm) // checkout srcs of this helper
    
		def pipelineHelper = load ('.jenkins_modules/JenkinsPipelineHelper.groovy')
		def gitlabCallbacks = load ('.jenkins_modules/GitlabNotification.groovy')
		def slackCallbacks = load ('.jenkins_modules/SlackNotification.groovy')





		// set pipeline data //

		Map<String,Closure> pipelineData = pipelineData ()





		// set pipeline callbacks //

		List<Map> callbackMapList = [
			gitlabCallbacks(),
			slackCallbacks(),
/*
			// custom callbacks if you want
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
				skipped: {pipeline, stageIdx, stateList -> echo ("customCB - skipped '${pipeline[stageIdx].stageName}'")},
			],
*/
		]

		Map<String,List<Closure>> callbackData = (
			['pending', 'running', 'passed', 'failed', 'aborted', 'canceled', 'skipped'].collectEntries { state ->
				[ (state): callbackMapList?.collect{ it?.get(state) }.flatten() ]
			}
		)




		// run pipeline //

		assert (
			// send triggered slack msg before running inner closure, then set env for running callbacks
			slackCallbacks.triggerAndEnableSlackMsgCallbacks {
				
				// inner closure
				withEnv (stageEnv()) {
					pipelineHelper (pipelineData, callbackData)
				}
			}
		)



	}
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

	// target repo config
	TARGET_REPO_CRED_ID: env.REPO_CRED_ID ?: "",

	// builder config
	BUILDER_IMG_NAME: env.IMG_BUILDER_IMG_NAME ?: "openjdk:latest",
	TESTER_IMG_NAME: env.IMG_TESTER_IMG_NAME ?: env.IMG_BUILDER_IMG_NAME ?: "openjdk:latest",
	DEPLOYER_IMG_NAME: env.IMG_DEPLOYER_IMG_NAME ?: "docker:latest",

	// docker private registry config
	PRIVATE_REG_URL: env.IMG_REGISTRY_URL ?: "http://127.0.0.1",
	PRIVATE_REG_PORT: env.IMG_REGISTRY_PORT ?: "5000",
	DEPLOY_IMG_NAME: env.IMG_NAME ?: "${env.gitlabSourceRepoName}".toLowerCase(), // Job name should be docker-img-name-compatible
	DEPLOY_IMG_TAG: env.IMG_TAG ?: "", // Real default value will be evaluated at runtime below
	DEPLOY_IMG_TO_LATEST: env.IMG_IS_LATEST ?: true,
	PRIVATE_REG_CRED_ID: env.IMG_REGISTRY_CRED_ID ?: "", // Registry credential on Jenkins config

].collect {"${it.key}=${it.value}"} }





/***************************************************
 *                                                 *
 *                  [ Pipeline ]                   *
 *                                                 *
 ***************************************************/


/**
 *   Get pipeline data
 *
 *       @return                     Map of [(stageName): (stageClosure)]
 */
Map<String,Closure> pipelineData () { [


// TO MAKE JENKINS SKIP STAGE, SET CLOSURE VALUE TO NULL (SEE 'DEPLOY' STAGE BELOW)
/***** Checkout Stage *****/

	('Checkout' + (env.gitlabMergeRequestIid != null ? ' & Merge' : '')) : {
		//checkout (scm)
		checkout ([
			$class: 'GitSCM',
			userRemoteConfigs: [[
				url: env.gitlabSourceRepoHttpUrl,
				credentialsId: env.TARGET_REPO_CRED_ID
			]],
			branches: [[name: "*/${env.gitlabSourceBranch}"]],
			extensions: [[
				$class: 'PreBuildMerge',
				options: [
					fastForwardMode: 'FF',
					mergeRemote: 'origin',
					mergeStrategy: 'DEFAULT',
					mergeTarget: env.gitlabTargetBranch
				]
			]],
		])
	},



/***** Build Stage *****/

	'Build': {

		docker.image(env.BUILDER_IMG_NAME).inside ("-u 0:0 -v $HOME/.gradle:${env.GRADLE_HOME_PATH}"){

			// parallel build
			parallel ([
				'Gradle Build': {

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

	'Test': {
		try {
			docker.image(env.TESTER_IMG_NAME).inside ("-u 0:0 -v $HOME/.gradle:${env.GRADLE_HOME_PATH}") {
				sh (
					label: 'Gradle Test',
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



/***** Deploy Stage *****/

	'Deploy': (env.gitlabMergeRequestIid != null) ? null : { // skip deploy stage if merge request

		if ( ! fileExists('Dockerfile') ) {
			echo ("Dockerfile not found. Built result not deployed.")
			return
		}

		String commitHash = sh (
				script: 'git rev-parse --short HEAD',
				returnStdout: true
			).trim()

		docker.image(env.DEPLOYER_IMG_NAME).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
			dockerImg = docker.build ("${env.DEPLOY_IMG_NAME}")
			docker.withRegistry ("${env.PRIVATE_REG_URL}:${env.PRIVATE_REG_PORT}", env.PRIVATE_REG_CRED_ID) {

				dockerImg.push ( "${env.DEPLOY_IMG_TAG ?: ("build-${env.BUILD_NUMBER}" + (commitHash ? "_" + commitHash : ""))}" )

				// latest
				if (env.DEPLOY_IMG_TO_LATEST.toBoolean()) {
					echo "Deploying previous image as additional tag 'latest'..."
					dockerImg.push ()
				}
			}
		}
	},




].asImmutable() }





// run main routine
main ()
