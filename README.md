# ![asda](https://github.com/Nikhil-Singh25/Images_logos/blob/main/pngwing.com%20(1).png)+![aws](https://github.com/Nikhil-Singh25/Images_logos/blob/main/pngwing.com.png)+![jenkins](https://github.com/Nikhil-Singh25/Images_logos/blob/main/jenkins100-100(3).png)</br>  Terraform-AWS + Jenkins Pipeline

This repo consists of :
  1. Terraform Configuration filesm, please refer to [Terraform Configuration Repository](https://github.com/Nikhil-Singh25/Terraform-VPC_Stack) to know more about configuration files.
  2. [Jenkinsfile](https://github.com/Nikhil-Singh25/tf_jenkinsProj/blob/main/Jenkinsfile) which automates infrastructure provisioning using Terraform.</br>
  The script consists of the following:</br>
   * `parameters`: Defines input parameters that can be used to customize the pipeline. In this case, a boolean parameter autoApprove is defined with a default value of false. This parameter will be used later to determine if the pipeline should automatically run the apply step or prompt the user for approval.
   * `environment`: Defines environment variables that will be available to all the steps in the pipeline. This is where the AWS credentials for the Jenkins server are defined.</br>
    - Save your `AWS_ACCESS_KEY_ID` & `AWS_SECRET_ACCESS_KEY` in your jenkins Server.
      ```groovy
        environment {           
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')  
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
      }

   * `agent`: Defines the node or agent on which the pipeline will run. In this case, the `any` option is used, which allows the pipeline to run on any available node.

  * `stages`: Represents logical divisions in the pipeline, each stage having one or more 
    1. `checkout`: This stage checks out the Terraform code from a GitHub repository & removes tf_jenkinsproj dir. everytime the job is run.
       ```groovy
          stage('checkout') {
            steps {             
                 dir('terraform'){
                    bat 'rmdir /s /q tf_jenkinsProj' 
                    bat 'git clone https://github.com/Nikhil-Singh25/tf_jenkinsProj.git'
                }
            }
        }
    2. `Plan`: This stage initializes Terraform and generates a plan for infrastructure changes and saving the plan in `tfplan.txt` file
       ```groovy
          stage('Plan') {          
            steps {
                bat 'cd terraform'
                bat 'terraform init'
                bat 'terraform plan -out tfplan'
                bat 'terraform show -no-color tfplan > tfplan.txt'
            }
        }
    3. `Approval`: This stage prompts the user to review the infrastructure changes and approve or reject them. If autoApprove is set to true, the pipeline will automatically run the apply step. If it is set to false, the user will be prompted for approval.
        ```groovy
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
                      input message: "Do you want to apply the plan?",
                      parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                }
            }
        }
    4. `Apply`: This stage applies the infrastructure changes by running the terraform apply command with the tfplan file generated in the previous stage.
        ```groovy
            stage('Apply') {
            steps {
                bat'cd terraform'
                bat 'terraform apply -input=false tfplan'
            }
        }
    
   * The entire script is wrapped in a pipeline block, which is the main structure of a Jenkins Pipeline script.
   
   
   ### Configuring Jenkins server to use the github repo :
   1. Create a `pipeline` job 
   2. **General** : Select 'this project is parameterised'-> Boolean Parameter -> Name: "autoApprove -> Description: "Automatically run apply after generating plan?"
   3. **Build Triggers**: You can check "GitHub hook trigger for GITScm polling"
   4. **Pipeline**: SCM: Git fill out the "repository URL" and "Branch specifier" accordignly in the end for ****Script path** :'Jenkinsfile'</br>
   **save and apply**