NAME = 'it/isUserTrigger'
DSL = '''pipeline {
  agent any
  stages {
    stage('checkout') {
      steps {
        gitCheckout(basedir: 'sub-folder', branch: 'master',
                    credentialsId: '2a9602aa-ab9f-4e52-baf3-b71ca88469c7-UserAndToken',
                    repo: 'https://github.com/octocat/Hello-World.git')
      }
    }
    stage('isUserTrigger') {
      steps {
        script {
          if (isUserTrigger()) {
            echo 'found'
          } else {
            echo 'not found'
          }
        }
      }
    }
  }
}'''

pipelineJob(NAME) {
  definition {
    cps {
      script(DSL.stripIndent())
    }
  }
}
