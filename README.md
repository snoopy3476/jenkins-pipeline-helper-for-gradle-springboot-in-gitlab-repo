# Jenkins Pipeline Helper for Gradle SpringBoot inside GitLab
Simple Jenkins Pipeline Runner for SpringBoot project stored in GitLab repository

## How to use
- Create new project (item) of Jenkins
- On `Pipeline` tab, select or input as followings:
  - `Definition`: `Pipeline script from SCM`
    - `SCM`: `Git`
      - `Repositories`
        - `Repository URL`: `https://github.com/snoopy3476/jenkins-pipeline-helper-for-gradle-springboot-inside-gitlab.git`
        - `Credentials`: `- none -`
      - `Branches to build`
        - `Branch Specifier`: (Branch/tag of this helper you want to use (e.g. `*/master` (branch), `tags/v0.1.1` (tag), ...))
    - `Script Path`: `Jenkinsfile`
- (Optional) If you want to change values for parameters inside the Jenkinsfile,
  - Check 'This project is parameterized' checkbox.
  - Add parameters you want, as `String Parameter`.
- Set the rest of the configs, according to your target repository.
