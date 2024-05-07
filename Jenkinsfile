pipeline {
    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')
    }

    parameters {
        string defaultValue: 'flare', description: 'Docker image that will run this build', name: 'AGENT_LABEL'
    }

    agent {
        label "${params.AGENT_LABEL}"
    }

    environment {
        PACKAGE_VERSION=15.0.0.${BUILD_NUMBER}
    }

    stages {
       

        stage('Build stage') {
            steps {
                powershell """
                    # Remove any NuGet packages from previous builds
                    if (Test-Path -Path *.nupkg -Type Leaf)
                    {
                        Remove-Item -Path *.nupkg
                    }

                    try
                    {
                        Write-Host "Building online help..."
                        .\\Invoke-FlareBuild.ps1 -FlareProjectFile .\\Flare_src\\NV_clientcontent.flprj -BatchTarget Both-mac-and-windows

                        # Copy external files into websites
                        Copy-Item .\\External_src\\welcome-screen\\win .\\Flare_src\\Output\jenkins\\windows-help\\Content\\welcome-screen -Recurse
                        Copy-Item .\\External_src\\welcome-screen\\mac .\\Flare_src\Output\\jenkins\\mac-help\\Content\\welcome-screen -Recurse
                    }
                    catch
                    {
                        Write-Error ("Build failure: {0}" -f $_.Exception)

                        # Ensure that the build fails
                        exit 1
                    }
                """
            }
        }

        stage("Trigger CreateAndPushDeploymentPackage windows-help"){
            steps{
                build job: 'CreateAndPushDeploymentPackage', \
                parameters: [string(name: 'PackageContentsSource', value: "${WORKSPACE}\\Flare_src\\Output\\jenkins\\windows-help"), \
                                string(name: 'PackageName', value: "nvivo14-win-clientcontent"), \
                                string(name: 'PackageVersion', value: "${PACKAGE_VERSION}"), \
                                string(name: 'PackageDescription', value: "Web content for NVivo 15 for Windows client"), \
                                string(name: 'PushToServerTimeout', value: "901"), \
                                [$class: 'LabelParameterValue', name: 'BuildNode', label: "${env.NODE_NAME}" ]], \
                wait: true
            }
        }

        stage("Copy windows-help artifact"){
            steps{
                copyArtifacts filter: '*.nupkg', fingerprintArtifacts: true, projectName: 'CreateAndPushDeploymentPackage', selector: lastSuccessful()
            }
        }

        stage("Trigger CreateAndPushDeploymentPackage windows-help"){
            steps{
                build job: 'CreateAndPushDeploymentPackage', \
                parameters: [string(name: 'PackageContentsSource', value: "${WORKSPACE}\\Flare_src\\Output\\jenkins\\mac-help"), \
                                string(name: 'PackageName', value: "nvivo14-mac-clientcontent"), \
                                string(name: 'PackageVersion', value: "${PACKAGE_VERSION}"), \
                                string(name: 'PackageDescription', value: "Web content for NVivo 14 for Mac client"), \
                                string(name: 'PushToServerTimeout', value: "901"), \
                                [$class: 'LabelParameterValue', name: 'BuildNode', label: "${env.NODE_NAME}" ]], \
                wait: true
            }
        }

         stage("Copy mac-help artifact"){
            steps{
                copyArtifacts filter: '*.nupkg', fingerprintArtifacts: true, projectName: 'CreateAndPushDeploymentPackage', selector: lastSuccessful()
            }
        }

        stage("Trigger DeployToTestEnvironment windows-help"){
            steps{
                build job: 'DeployToTestEnvironment', \
                parameters: [string(name: 'OctopusProjectName', value: 'NVivo 14 for Windows Client Content'), \
                                string(name: 'ReleaseVersion', value: '${PACKAGE_VERSION}'), \
                                string(name: 'EnvironmentName', value: 'content-test'), \
                                [$class: 'LabelParameterValue', name: 'BuildNode', label: "${env.NODE_NAME}" ]]
            }
        }

        stage("Trigger DeployToTestEnvironment mac-help"){
            steps{
                build job: 'DeployToTestEnvironment', \
                parameters: [string(name: 'OctopusProjectName', value: 'NVivo 14 for Mac Client Content'), \
                                string(name: 'ReleaseVersion', value: '${PACKAGE_VERSION}'), \
                                string(name: 'EnvironmentName', value: 'content-test'), \
                                [$class: 'LabelParameterValue', name: 'BuildNode', label: "${env.NODE_NAME}" ]]
            }
        }

        stage('Compress Output for Archiving'){
            steps{
                powershell """
                    # Compress Output for Archiving
                    try
                    {
                        Write-Host "Compressing Windows Output..."
                        Compress-Archive -Path .\\Flare_src\\Output\\jenkins\\windows-help -DestinationPath .\\nvivo14-win-clientcontent.zip
                    }
                    catch
                    {
                        Write-Error ("Compression Failure: {0}" -f $_.Exception)

                        # Ensure that the build fails
                        exit 1
                    }

                    try
                    {
                        Write-Host "Compressing Mac Output..."
                        Compress-Archive -Path .\\Flare_src\\Output\\jenkins\\mac-help -DestinationPath .\nvivo14-mac-clientcontent.zip
                    }
                    catch
                    {
                        Write-Error ("Compression Failure: {0}" -f $_.Exception)

                        # Ensure that the build fails
                        exit 1
                    }
                """
            }
        }
    }

    post {
        always {
            script{
                // Post  Build Steps to Archive the Build Files and Publish the Unit Test Reports
                echo 'Post Build Activities'
                archive '*.nupkg,*.zip'
            }
        }
    }
}
