# Continuous integration and delivery implementation in android using bitbucket pipelines
“Continuous Integration doesn’t get rid of bugs, but it does make them dramatically easier to find and remove them.”
 — Martin Fowler, Chief Scientist, ThoughtWorks

# Overview
Continuous integration systems let you automatically build and test your app every time you check-in updates to your source control system.
Whenever developers check-in code in a shared repository, it is verified by an automated build, allowing teams to detect problems early. By integrating regularly, you can detect errors quickly, and locate them more easily.

# Goals
1. Create and sign a release build of UAT flavor upon a check-in in develop branch.
2. Create and sign a release builds of Production flavor upon closing a release branch and publish it on Google Play Store.

# Prerequisite
1. Basic knowledge of [YAML](https://learn.getgrav.org/advanced/yaml).
2. Basic knowledge of [bash scripts](https://learn.getgrav.org/advanced/yaml).

# Steps
## 1. Setup a repository in bitbucket
   Create a new repository in bitbucket and set up gitignore and other properties.
   
## 2. Create a Google Play Store listing for your project and upload a build alpha release.
  Create playstore listing for the project and deploy first release in alpha channel.
  
## 3. Create a service account to access Google Play Developer API. Create a cloud project and download the google play store credentials.
  We will need a service account to allow an application to deply release on behalf of us.
  Follow [this link](https://developers.google.com/android/management/service-account) to create a service account.
  
## 4. Create a properties file to save your keystore properties. Zip files and save them in your file server.

## 5. Write custom tasks to download and extract these files in build directory.

  1. Create a blank keystore.properties file in the root directory.
  2. Add download task. Add `undercouch` plugin in root gradle to download files from remote file server.
 ```
 plugins {
    id 'de.undercouch.download' version '3.3.0'
  }
```
  3. Add extract task.
  4. Add task to write keystore properties to local file.
  
## 6. Setup build types. (Release and debug) Debug builds won’t get signed.

## 7. Setup signin config. 
  1. Create a global variable for KeyStore Properties.
  2. Load the keystore.properties file in variable.
  3. Set the signing credentials
 ```groovy
 
  android {
    ...
     signingConfigs {
        release {
            keystoreProperties.load(new FileInputStream(file("${project.rootDir}/keystore.properties")))
            storeFile file('build/MyKey.jks')
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storePassword keystoreProperties['storePassword']
        }
    }
    ...
    }
 ```
 
## 8. Enable bitbucket pipeline
  1. Open your repository on bitbucket.org for which you want to implement CI.
  2. Click on pipeline icon, choose language template as Java (Gradle) and add the following YAML script to it and commit changes.

```
image: uber/android-build-environment:latest

pipelines:
  tags:
   ‘**’:
      - step:
          script:
            - ./build.sh 0
            - . ./setup_export.sh
            ##########  UPLOAD TO BITBUCKET DOWNLOADS ##########
            # Instructions to setup the next line. https://confluence.atlassian.com/bitbucket/deploy-build-artifacts-to-bitbucket-downloads-872124574.html
            - curl -X POST --user "${BB_AUTH_STRING}" "https://api.bitbucket.org/2.0/repositories/${BITBUCKET_REPO_OWNER}/${BITBUCKET_REPO_SLUG}/release/downloads" --form files=@"${LATEST_APK}"

  branches:
    develop:
      - step:
         script:
           - ./build.sh 1
           - . ./setup_export.sh
            ##########  UPLOAD TO BITBUCKET DOWNLOADS ##########
            # Instructions to setup the next line. https://confluence.atlassian.com/bitbucket/deploy-build-artifacts-to-bitbucket-downloads-872124574.html
           - curl -X POST --user "${BB_AUTH_STRING}" "https://api.bitbucket.org/2.0/repositories/${BITBUCKET_REPO_OWNER}/${BITBUCKET_REPO_SLUG}/develop/downloads" --form files=@"${LATEST_APK}"
```


`The first line is for declaring the build environment for building the apps.
Uber is a predefined build environment by Docker  which we are going to use for creating a virtual build system in bitbucket cloud.`

## 9. Add shell scripts to project and make them executable.
  1. Add build.sh.
  2. Add setup_export.sh.
  3. Set both the shell script files and gradlew executable by running following command in terminal.
  
     ``git update-index --chmod=+x <file>``
  
  4. Edit build.sh to perform tasks according to type of pipeline.
  
## 10. Setup Play Store deployment setup.

  1. Add triplet library to root level gradle.
  ```groovy
buildscript {

    repositories {
        mavenCentral()
    }

    dependencies {
    	// ...
        classpath 'com.github.triplet.gradle:play-publisher:1.2.0'
    }
}
```
  2. Add triplet plugin in app level gradle.
  ```groovy
apply plugin:'com.android.application'
apply plugin: 'com.github.triplet.play'
```
  3. Add playAccountConfigs and playAccountConfig in app level gradle.
  ```groovy
  android {

    playAccountConfigs {
        defaultAccountConfig {
            jsonFile = file('build/playstore_credentials.json')
        }
    }
    
     defaultConfig {
     ...
        playAccountConfig = playAccountConfigs.defaultAccountConfig
    }

  ...
  }
  ```
