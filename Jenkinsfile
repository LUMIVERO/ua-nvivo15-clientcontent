pipeline {
    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')
    }

    agent {
        label "flare"
    }

    environment {
        PACKAGE_VERSION="15.0.0.${BUILD_NUMBER}"
        OCTOPUS_PROJECT_WIN="NVivo 15 for Windows Client Content"
        OCTOPUS_PROJECT_MAC="NVivo 15 for Mac Client Content"
        NUGET_PKG_WIN="nvivo15-win-clientcontent"
        NUGET_PKG_MAC="nvivo15-mac-clientcontent"
        FLARE_PROJECT_NAME=".\\Flare_src\\NV15_clientcontent.flprj"
    }

    stages {
       

        stage('Build stage') {
            steps {
                powershell '''
                    # Remove any NuGet packages from previous builds
                    if (Test-Path -Path *.nupkg -Type Leaf)
                    {
                        Remove-Item -Path *.nupkg
                    }

                    try
                    {
                        Write-Host "Building online help..."
                        .\\Invoke-FlareBuild.ps1 -FlareProjectFile $env:FLARE_PROJECT_NAME -BatchTarget Both-mac-and-windows

                        # Copy external files into websites
                        Copy-Item .\\External_src\\welcome-screen\\win .\\Flare_src\\Output\\jenkins\\windows-help\\Content\\welcome-screen -Recurse
                        Copy-Item .\\External_src\\welcome-screen\\mac .\\Flare_src\\Output\\jenkins\\mac-help\\Content\\welcome-screen -Recurse
                    }
                    catch
                    {
                        Write-Error ("Build failure: {0}" -f $_.Exception)

                        # Ensure that the build fails
                        exit 1
                    }
                '''
            }
        }

        stage('Create windows and mac help packges') {
            stages{
                stage("Trigger CreateAndPushDeploymentPackage for windows"){
                    steps{
                        build job: 'CreateAndPushDeploymentPackage', \
                        parameters: [string(name: 'PackageContentsSource', value: "${WORKSPACE}\\Flare_src\\Output\\jenkins\\windows-help"), \
                                        string(name: 'PackageName', value: "${NUGET_PKG_WIN}"), \
                                        string(name: 'PackageVersion', value: "${PACKAGE_VERSION}"), \
                                        string(name: 'PackageDescription', value: "Web content for NVivo 15 for Windows client"), \
                                        string(name: 'PushToServerTimeout', value: "9001"), \
                                        [$class: 'LabelParameterValue', name: 'BuildNode', label: "${env.NODE_NAME}" ]], \
                        wait: true
                        copyArtifacts filter: '*.nupkg', fingerprintArtifacts: true, projectName: 'CreateAndPushDeploymentPackage'
                    }
                }
                stage("Trigger CreateAndPushDeploymentPackage for mac"){
                    steps{
                        build job: 'CreateAndPushDeploymentPackage', \
                        parameters: [string(name: 'PackageContentsSource', value: "${WORKSPACE}\\Flare_src\\Output\\jenkins\\mac-help"), \
                                        string(name: 'PackageName', value: "${NUGET_PKG_MAC}"), \
                                        string(name: 'PackageVersion', value: "${PACKAGE_VERSION}"), \
                                        string(name: 'PackageDescription', value: "Web content for NVivo 15 for Mac client"), \
                                        string(name: 'PushToServerTimeout', value: "9001"), \
                                        [$class: 'LabelParameterValue', name: 'BuildNode', label: "${env.NODE_NAME}" ]], \
                        wait: true

                        copyArtifacts filter: '*.nupkg', fingerprintArtifacts: true, projectName: 'CreateAndPushDeploymentPackage'
                    }
                }
            }
        }

        stage("Deploy windows and mac help packges"){
            stages{
                stage("Deploy to test environment for windows"){
                    steps{
                        build job: 'DeployToTestEnvironment', \
                        parameters: [string(name: 'OctopusProjectName', value: "${OCTOPUS_PROJECT_WIN}"), \
                                        string(name: 'ReleaseVersion', value: "${PACKAGE_VERSION}"), \
                                        string(name: 'EnvironmentName', value: "content-test"), \
                                        [$class: 'LabelParameterValue', name: 'BuildNode', label: "${env.NODE_NAME}" ]]
                    }
                }

                stage("Deploy to test environment for mac"){
                    steps{
                        build job: 'DeployToTestEnvironment', \
                        parameters: [string(name: 'OctopusProjectName', value: "${OCTOPUS_PROJECT_MAC}"), \
                                        string(name: 'ReleaseVersion', value: "${PACKAGE_VERSION}"), \
                                        string(name: 'EnvironmentName', value: "content-test"), \
                                        [$class: 'LabelParameterValue', name: 'BuildNode', label: "${env.NODE_NAME}" ]]
                    }
                }
            }
        }

        // stage('Create windows and Mac zip files'){
        //     steps{
        //         powershell '''
        //             # Compress Output for Archiving
        //             try
        //             {
        //                 Write-Host "Compressing Windows Output..."
        //                 Compress-Archive -Path .\\Flare_src\\Output\\jenkins\\windows-help -DestinationPath .\\nvivo15-win-clientcontent.zip
        //             }
        //             catch
        //             {
        //                 Write-Error ("Compression Failure: {0}" -f $_.Exception)

        //                 # Ensure that the build fails
        //                 exit 1
        //             }

        //             try
        //             {
        //                 Write-Host "Compressing Mac Output..."
        //                 Compress-Archive -Path .\\Flare_src\\Output\\jenkins\\mac-help -DestinationPath .\nvivo15-mac-clientcontent.zip
        //             }
        //             catch
        //             {
        //                 Write-Error ("Compression Failure: {0}" -f $_.Exception)

        //                 # Ensure that the build fails
        //                 exit 1
        //             }
        //         '''
        //     }
        // }
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
