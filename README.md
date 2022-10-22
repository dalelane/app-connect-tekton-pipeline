# Example pipeline for App Connect Enterprise

**An example Tekton pipeline for deploying an IBM App Connect Enterprise application to Red Hat OpenShift.**

- [Overview](#overview)
- [Pipelines](#pipelines)
- [Sample ACE apps](#sample-apps)
- [Building your own app](#configuring-the-pipeline-for-your-app-connect-enterprise-application)
- [Supported versions](#supported-versions)
- [More info](#more-info)

## Overview

This repository contains an example of how to use [Tekton](https://tekton.dev) to create a CI/CD pipeline that builds and deploys an [App Connect Enterprise](https://www.ibm.com/docs/en/app-connect/containers_cd) application to [Red Hat OpenShift](https://www.ibm.com/cloud/openshift).

![animated gif](./screenshots/complex-pipeline.gif)

This pipeline uses the [IBM App Connect Operator](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=operator-from-openshift-web-console) to easily build, deploy and manage your applications in containers. The pipeline runs on OpenShift to allow it to easily be integrated into an automated [continuous delivery workflow](https://www.ibm.com/garage/method/practices/deliver/practice_continuous_delivery/) without needing to build anything locally from a developer's workstation.

> For background information about the Operator, and the different resources that this pipeline will create (e.g. `IntegrationServer` and `Configuration`), see these blog posts:
> - [What is an Operator and why did we create one for IBM App Connect?](https://community.ibm.com/community/user/integration/blogs/rob-convery1/2022/05/11/ibm-app-connect-operators-part-1-what-is-an-operat)
> - [Exploring the IntegrationServer Resource of the IBM App Connect Operator](https://community.ibm.com/community/user/integration/blogs/rob-convery1/2022/05/11/ibm-app-connect-operators-part-2-exploring)


## Pipelines

### Overview
There are two pipelines in this repository.

- [image builder](#image-builder-pipeline)
    - This builds a container image that the second pipeline uses to build App Connect BAR files.
    - You only need to run this once on your OpenShift cluster - once you have your builder image, you can reuse it every time you need to build and deploy your App Connect application.
- [application deployer](#application-deployer-pipeline)
    - This builds and deploys your App Connect Enterprise application.
    - You need to run this every time your application has changed and you want to deploy the new version to OpenShift.

### Image builder pipeline

|  | **link** |
| - | - |
| **pipeline spec:** | [`1-prepare-builder/pipeline.yaml`](./tekton/1-prepare-builder/pipeline.yaml) |
| **permissions created to run this pipeline** | [`builder.yaml` role](./tekton/1-prepare-builder/permissions/builder.yaml) |
| **example pipeline runs:** | [`1-prepare-builder/pipelinerun.yaml`](./tekton/1-prepare-builder/pipelinerun.yaml) |
| **helper script:** | [`1-prepare-ace-bar-builder.sh`](./1-prepare-ace-bar-builder.sh) |

**What the pipeline does**

Builds a container image used by the [application deployer pipeline](#application-deployer-pipeline) to build BAR files.

**Outcome from running the pipeline**

A new container image is pushed to the OpenShift image registry in the `pipeline-ace` namespace, which has everything needed to run the `mqsicreatebar` command.

**Screenshot**

![screenshot of the pipeline tasks](./screenshots/builder-pipeline.png)

**Background**

When running App Connect Enterprise in containers, there is a lot of flexibility about how much of your application is built into your container image, and how much is provided when the container starts.

> For background reading on some of the options, and some of the considerations about them, see the blog post:
> - [Comparing styles of container-based deployment for IBM App Connect Enterprise](https://community.ibm.com/community/user/integration/blogs/aiden-gallagher1/2022/07/12/comparing-styles-of-container-based-deployment-for)

The pipelines in this repository provide almost all parts of your application at runtime when the container starts. The only component that is [baked into](https://community.ibm.com/community/user/integration/blogs/aiden-gallagher1/2022/07/12/comparing-styles-of-container-based-deployment-for) the image is the application BAR file.

Baking the BAR files into custom App Connect images prevents the need to run a dedicated content server to host BAR files, however if you would prefer to do that see the documentation on [Mechanisms for providing BAR files to an integration server](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=servers-mechanisms-providing-bar-files-integration-server) for more details on how to do this. (The pipelines in this repository use the approach described as "Custom image" in that documentation.)

Building this image is kept separate from the [application deployer pipeline](#application-deployer-pipeline) because it takes a long time (over 20 minutes) to run. Reusing the build image means application deployments can be much quicker.

### Application deployer pipeline

|  | **link** |
| - | - |
| **pipeline spec:** | [`2-deploy-integration-server/pipeline.yaml`](./tekton/2-deploy-integration-server/pipeline.yaml) |
| **example pipeline runs:** | [`simple-pipelinerun.yaml`](./simple-pipelinerun.yaml) <br>[`complex-pipelinerun.yaml`](./complex-pipelinerun.yaml) |
| **helper scripts:** | [`2-deploy-simple-integration-server.sh`](./2-deploy-simple-integration-server.sh) <br>[`2-deploy-complex-integration-server.sh`](./2-deploy-complex-integration-server.sh)


**What the pipeline does**

Builds your IBM App Connect Enterprise application and deploys it to the OpenShift cluster.

**Outcome from running the pipeline**

A new version of your application is deployed with zero-downtime - replacing any existing version of the app once it is ready.

**Screenshot**

![screenshot of the deploy pipeline tasks](./screenshots/deploy-pipeline.png)

**Background**

As discussed above, most of your application configuration will be provided to your application container at runtime by the Operator using `Configuration` resources.

As shown in the screenshot above, this example pipeline currently supports many, but not all, of the types of Configuration resource:
- [Loopback data source type](https://www.ibm.com/docs/en/SSTTDS_contcd/com.ibm.ace.icp.doc/config_loopbackdatasource.html)
- [Policy project type](https://www.ibm.com/docs/en/SSTTDS_contcd/com.ibm.ace.icp.doc/config_policyproject.html)
- [setdbparms.txt type](https://www.ibm.com/docs/en/SSTTDS_contcd/com.ibm.ace.icp.doc/config_setdbparmstxt.html)
- [server.conf.yaml type](https://www.ibm.com/docs/en/SSTTDS_contcd/com.ibm.ace.icp.doc/config_serverconfyaml.html)
- [Truststore type](https://www.ibm.com/docs/en/SSTTDS_contcd/com.ibm.ace.icp.doc/config_truststore.html)

For more information about the other Configuration types, see the documentation on [Configuration types for integration servers](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=servers-configuration-types-integration). Adding support for any of these additional types would involve adding additional tasks to the [tasks provided in this repo](./tekton/2-deploy-integration-server/tasks/) - the existing tasks are commented to help assist with this.

Each of these configuration resources is individually optional. Two example App Connect applications are provided to show how the pipeline supports different application types.

#### Simple stand-alone applications

The pipeline can be used to deploy a stand-alone application with no configuration dependencies.

| | **link** |
| - | - |
| **sample application** | [simple-demo](./ace-projects/simple-demo/) |
| **pipeline run config** | [`simple-pipelinerun.yaml`](./simple-pipelinerun.yaml) |
| **demo script:** | [`2-deploy-simple-integration-server.sh`](./2-deploy-simple-integration-server.sh) |

![screenshot](./demo-pre-reqs/images/simple-demo.png)

This is a simple App Connect application with no external configuration.

![screenshot](./demo-pre-reqs/images/say_hello.png)

When deploying this, the pipeline skips all of the Configuration tasks:

![screenshot of a pipeline run for the simple app](./screenshots/example-pipelinerun-simple.png)

Watching the pipeline run looks like this (except it takes longer).

![animated gif](./screenshots/simple-pipeline.gif)

#### Complex applications

The pipeline can be used to deploy complex applications with multiple configuration dependencies and supporting Java projects.

| | **link** |
| - | - |
| **sample application** | [sample-ace-application](./ace-projects/sample-ace-application/) |
| **pipeline run config** | [`complex-pipelinerun.yaml`](./complex-pipelinerun.yaml) |
| **demo script:** | [`2-deploy-complex-integration-server.sh`](./2-deploy-complex-integration-server.sh) |

![screenshot](./demo-pre-reqs/images/sample-ace-application.png)

This is an example of an App Connect application that needs configuration for connecting to:
- a PostgreSQL database
- an external HTTP API
- an Apache Kafka cluster

![screenshot](./demo-pre-reqs/images/sample_message_flow.png)

When deploying this, the pipeline runs all of the Configuration tasks required for this application:

![screenshot of a pipeline run for the complex app](./screenshots/example-pipelinerun-complex.png)

Watching the pipeline run (also sped up!) it looks like this.

![animated gif](./screenshots/complex-pipeline.gif)

To avoid needing to store credentials in git with your application code, the pipeline retrieves credentials from Kubernetes secrets. When [configuring the pipeline for your application](#configuring-the-pipeline-for-your-app-connect-enterprise-application) you need to specify the secrets it should use to do this.

## Sample apps

I've put notes on how I set up the sample apps to demonstrate the pipeline in [demo-pre-reqs/README.md](./demo-pre-reqs/README.md) however neither of the sample apps are particularly useful and were purely used to test and demo the pipeline.

You can import them into [App Connect Toolkit](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=developing-integrations-in-app-connect-toolkit) to edit them if you want to by:

1. **File** -> **Import...** -> **Projects from Folder or Archive**
2. Put the location of the [ace-projects](./ace-projects/) folder as the **Import source**.
3. Tick all of the projects

That will let you open the projects and work on them locally. If you're curious what they do, I'll include some brief notes below:

### Simple app

It provides an HTTP endpoint that returns a Hello World message.

![screenshot of the message flow](./demo-pre-reqs/images/say_hello.png)

Running this:
```sh
curl "http://$(oc get route -nace-demo hello-world-http -o jsonpath='{.spec.host}')/hello"
```

returns this:
```json
{"hello":"world"}
```

### Complex app

It provides an intentionally contrived event-driven flow that:
- "Kafka consumer todo updates"
    - receives a JSON message from a Kafka topic
- "get id from update message"
    - parses the JSON message and extracts an ID number from it
    - uses the id number to create an HTTP URL for an external API
- "retrieve current todo details"
    - makes an HTTP GET call to the external API
- "base64 encode the description"
    - transforms the response from the external API using a custom Java class
- "insert into database"
    - inserts the transformed response payload into a PostgreSQL database

![screenshot of the message flow](./demo-pre-reqs/images/sample_message_flow.png)

The aim of this application was to demonstrate an ACE application which needed a variety of Configuration resources.

But it means that running this:
```sh
echo '{"id": 1, "message": "quick test"}' | kafka-console-producer.sh \
    --bootstrap-server $BOOTSTRAP \
    --topic TODO.UPDATES \
    --producer-property "security.protocol=SASL_SSL" \
    --producer-property "sasl.mechanism=SCRAM-SHA-512" \
    --producer-property "sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username="appconnect-kafka-user" password="$PASSWORD";" \
    --producer-property "ssl.truststore.location=ca.p12" \
    --producer-property "ssl.truststore.type=PKCS12" \
    --producer-property "ssl.truststore.password=$CA_PASSWORD"
```

gets you this:
```
store=# select * from todos;
 id | user_id |       title        |            encoded_title             | is_completed
----+---------+--------------------+--------------------------------------+--------------
  1 |       1 | delectus aut autem | RU5DT0RFRDogZGVsZWN0dXMgYXV0IGF1dGVt | f
(1 row)
```

## Configuring the pipeline for your App Connect Enterprise application

The [image builder pipeline](#image-builder-pipeline) can be run as-is as described above, as it is a generic pipeline for creating a container image for building App Connect apps.

To run the [application deployer](#application-deployer-pipeline) for your own application, you need to first create a `PipelineRun`.

The sample pipeline runs described above provide a good starting point for this, which you can modify to your own needs. You need to specify the location of your App Connect Enterprise application code and configuration resources. All of the available parameters are documented in the [pipeline spec](./tekton/2-deploy-integration-server/pipeline.yaml#L20-L191) if further guidance is needed.


## Supported versions

This sample pipeline was tested on OpenShift 4.10.

You can see the versions of what I was running on OpenShift at [./demo-pre-reqs/operators/](./demo-pre-reqs/operators/). It is possible that this pipeline would need modifying to work with different versions of OpenShift, Tekton, or App Connect.

## More info

For help with using this or if you have any questions, please create an issue or <a href="https://github.com/dalelane">contact me</a>.
