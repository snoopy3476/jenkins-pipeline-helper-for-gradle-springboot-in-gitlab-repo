# Jenkins Pipeline Helper for Gradle SpringBoot in GitLab repo
Simple Demo Jenkins Pipeline Runner for SpringBoot project managed with GitLab repository (both gitlab.com and private)

## Prerequisites
- A gradle SpringBoot project repository in GitLab
- A Jenkins pipeline project, that this Jenkins Pipeline Helper is applied  
  (See [How to Configure](#how-to-configure) section below)
- Webhook integrations configured between the two above  
  (GitLab repository ⇔ Jenkins project)

## What Does This Do
- Whenever someone git push or merge request to Gradle SpringBoot repository in GitLab:
  
  - Run the series of stages in Jenkins:
    - `Checkout (& Merge)`: Git checkout
      - If input webhook is from GitLab merge request, do fast-forward merge with target repository.
    - `Build`: Gradle build
    - `Test`: Gradle test
    - `Deploy`: Docker push to a remote image registry
      - For this deploy stage to work properly, following requirements should be met:
        - Dockerfile should be placed at the repository root.
        - Configuration is required using Jenkins project parameter below. (Parameters starting with `IMG_REGISTRY_`...)
  
  ![jenkins-pipeline-img.png](https://github.com/snoopy3476/jenkins-pipeline-helper-for-gradle-springboot-in-gitlab-repo/blob/135c8b5c3c4402dedac81eef3bf539c001f5d20a/.readme-img/jenkins-pipeline-img.png?raw=true)
  
  - Send realtime notification messages to GitLab and Slack, while running each stages above  
    (if related plugins [`GitLab`](https://plugins.jenkins.io/gitlab-plugin/), [`Slack Notification`](https://plugins.jenkins.io/slack/) are installed then preconfigured on Jenkins configuration)
    
    - Note: When configuring `Slack Notification` plugin, you should create your own new Slack app with [`Bot user mode`](https://plugins.jenkins.io/slack/#plugin-content-bot-user-mode).
  
  ![noti-slack-animation.gif](https://github.com/snoopy3476/jenkins-pipeline-helper-for-gradle-springboot-in-gitlab-repo/blob/135c8b5c3c4402dedac81eef3bf539c001f5d20a/.readme-img/noti-slack-animation.gif?raw=true)
  
  ![noti-slack-img.png](https://github.com/snoopy3476/jenkins-pipeline-helper-for-gradle-springboot-in-gitlab-repo/blob/135c8b5c3c4402dedac81eef3bf539c001f5d20a/.readme-img/noti-slack-img.png?raw=true)
  
  ![noti-gitlab-img.png](https://github.com/snoopy3476/jenkins-pipeline-helper-for-gradle-springboot-in-gitlab-repo/blob/135c8b5c3c4402dedac81eef3bf539c001f5d20a/.readme-img/noti-gitlab-img.png?raw=true)
  


## How to Configure
- Create a new project (item) on Jenkins.
- On `Pipeline` tab, select or input as followings:
  - `Definition`: `Pipeline script from SCM`
    - `SCM`: `Git`
      - `Repositories`
        - `Repository URL`: (URL of the current pipeline helper repository)
        - `Credentials`: `- none -`
      - `Branches to build`
        - `Branch Specifier`: (Tag/branch of this helper you want to use)
          - E.g) `tags/v0.1.3` (tag - recommended), `*/master` (branch), ...
    - `Script Path`: `Jenkinsfile`
    
  ![pipeline-config-img.png](https://github.com/snoopy3476/jenkins-pipeline-helper-for-gradle-springboot-in-gitlab-repo/blob/135c8b5c3c4402dedac81eef3bf539c001f5d20a/.readme-img/pipeline-config-img.png?raw=true)

- (Optional) If you want to change values for parameters inside the `Jenkinsfile`:
  - Check `This project is parameterized` checkbox.
  - Add parameters you want, as `String Parameter`.
  - Available parameters
    - `REPO_CRED_ID`: ID of a Jenkins credential for a target repo you want to build
      - Type: String
      - Default: `""`
    - `IMG_BUILDER_IMG_NAME`: Image to use when building a target repo
      - Type: String
      - Default: `"openjdk:latest"`
    - `IMG_TESTER_IMG_NAME`: Image to use when testing the built result of target repo
      - Type: String
      - Default: `"openjdk:latest"`
    - `IMG_DEPLOYER_IMG_NAME`: Image to use when deploying the built result to remote registry
      - Type: String
      - Default: `"docker:latest"`
    - `IMG_REGISTRY_URL`: Url of a remote registry to deploy built image
      - Type: String
      - Default: `"http://127.0.0.1"`
    - `IMG_REGISTRY_PORT`: Port of a remote registry to deploy built image
      - Type: String
      - Default: `"5000"`
    - `IMG_REGISTRY_CRED_ID`: ID of a Jenkins credential for a remote registry you want to deploy
      - Type: String
      - Default: `""`
    - `IMG_NAME`: Name of an image you want inside a remote registry
      - Type: String
      - Default: `"${env.gitlabSourceRepoName}".toLowerCase()`
    - `IMG_TAG`: Tag of an image you want inside a remote registry
      - Type: String
      - Default: `"build-${env.BUILD_NUMBER}_${commitHash}"`
    - `IMG_IS_LATEST`: Current image is also set as 'latest' tag, in addition to IMG_TAG
      - Type: Boolean
      - Default: `true`
    - `SLACK_MSG_CH`: Channel of Slack to send notification
      - Type: String
      - Default: Slack plugin configuration default
    
  ![parameter-config-img.png](https://github.com/snoopy3476/jenkins-pipeline-helper-for-gradle-springboot-in-gitlab-repo/blob/135c8b5c3c4402dedac81eef3bf539c001f5d20a/.readme-img/parameter-config-img.png?raw=true)

- Set the rest of the configs, according to your target repository.

## Using Different Pipeline
To use your own custom pipeline other than the current simple demo (maintaining message functions to GitLab and Slack),
- Fork or clone this repository
- Modify contents of pipeline in `Map<String,Closure> pipelineData ()` method inside `Jenkinsfile`
  - Key is name of a stage, and value is a closure to run at that stage
    - If the value is null, the stage will be skipped, and also marked as 'skipped' on Jenkins and Slack.


## Author
Kim Hwiwon \<kim.hwiwon@outlook.com\>

## License
The MIT License (MIT)
