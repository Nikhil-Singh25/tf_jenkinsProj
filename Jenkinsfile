pipeline {

    parameters {                //To define input parameters that can be used to customize a pipeline.
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
    } 
    environment {           //Defines env variables that will be available to all the steps in pipeline
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')  //create these credentials in you jenkins server/node
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }

   agent  any                  //Defines node or agent on which the pipeline will run,`any` allows the pipleline to run on any available node
    stages {                   //represent logical division in the pipeline, each stage have one or more `steps`         
        stage('checkout') {
            steps {             //defines individual steps that make up a stage(can be a shell command, a script, or a plugin command)
                 bat '''
                    cd terraform
                    git clone https://github.com/yeshwanthlm/Terraform-Jenkins.git
                 '''
                }
            }

        stage('Plan') {          //terraform init => terrafrom plan and saving the plan in tfplan => tfplan.txt
            steps {
                bat 'cd terraform && terraform init'
                bat 'cd terraform && terraform plan -out tfplan'
                bat 'cd terraform && terraform show -no-color tfplan > tfplan.txt'
            }
        }
        stage('Approval') {         
           when {               
            // to conditionally execute `approve` stage if `autoApprove=true` pipeline will run automatically and prompt user if `autoApprove=false`
               not {
                   equals expected: true, actual: params.autoApprove
               }
           }

           steps {
               script {
                    def plan = readFile 'terraform/tfplan.txt'      
                    //read the contents of a file named tfplan.txt, which was generated in the previous Plan stage(line-28)
                    input message: "Do you want to apply the plan?", //The input step is used to prompt the user for approval to apply the plan
                    parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
               }
           }
       }

        stage('Apply') {
            steps {
                bat 'cd terraform && terraform apply -input=false tfplan'
            }
        }
    }

  }