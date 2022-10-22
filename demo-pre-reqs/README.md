# demo prep

**You (almost certainly) don't need this.**

These are the pre-reqs I used to demonstrate my sample App Connect Enterprise application. My App Connect application connects to a PostgreSQL database - so I need to set up a PostgreSQL database to demo it. My App Connect application receives messages from Kafka - so I need to create a Kafka cluster to demo it. And so on.

I'm keeping this here as it'll be convenient when I need to recreate this demo from scratch, but as you'll be building and deploying your own App Connect Enterprise application, **you will have different pre-reqs to me**.

If you just follow these instructions on your existing OpenShift cluster, you will likely find some of this clashes with what you already have set up on your cluster.

## Add IBM software to Operator Hub

```sh
oc apply -f ibm-catalog-source.yaml
```

## Install operators needed for the demo

```sh
oc apply -f operators
```

## Setup Platform Navigator

```sh
oc new-project integration
oc apply -f ./ibm-entitlement-key.yaml -n integration
oc apply -f ./cp4i
```

## Setup Event Streams

```sh
oc new-project eventstreams
oc apply -f ./ibm-entitlement-key.yaml -n eventstreams
oc apply -f ./kafka
```

## Setup PostgreSQL

```sh
oc new-project postgresql
oc apply -f ./postgresql/db-data.yaml
oc apply -f ./postgresql/database.yaml
```

## Setup the namespace where the sample ACE demo will run

```sh
oc new-project ace-demo
oc apply -f ./ibm-entitlement-key.yaml -n ace-demo
```

## Submit an HTTP request to the simple ACE flow

```sh
curl "http://$(oc get route -nace-demo hello-world-http -o jsonpath='{.spec.host}')/hello"
```

## Produce a message to the Kafka topic that will trigger the complex ACE flow

```sh
BOOTSTRAP=$(oc get eventstreams event-backbone -neventstreams -ojsonpath='{.status.kafkaListeners[1].bootstrapServers}')
PASSWORD=$(oc get secret -neventstreams appconnect-kafka-user -ojsonpath='{.data.password}' | base64 -d)
oc get secret -neventstreams event-backbone-cluster-ca-cert -ojsonpath='{.data.ca\.p12}' | base64 -d > ca.p12
CA_PASSWORD=$(oc get secret -neventstreams event-backbone-cluster-ca-cert -ojsonpath='{.data.ca\.password}' | base64 -d)

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

## Check that the ACE flow put something in PostgreSQL

```sh
oc exec -it -n postgresql -c database \
  $(oc get pods -n postgresql --selector='postgres-operator.crunchydata.com/cluster=store,postgres-operator.crunchydata.com/role=master' -o name) \
  -- psql -d store
```

```sql
store=# select * from todos;
 id | user_id |       title        |            encoded_title             | is_completed
----+---------+--------------------+--------------------------------------+--------------
  1 |       1 | delectus aut autem | RU5DT0RFRDogZGVsZWN0dXMgYXV0IGF1dGVt | f
(1 row)
```