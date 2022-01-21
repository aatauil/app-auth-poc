# app-centrale-vindplaats

  <br>

## Table of content


* [Description](#description)
* [List of services](#list-of-services)
* [Setup](#setup)
* [Importing Data](#importing-data)
   *  [Data sources](#data-sources)
 * [Frontend](#frontend)
   * [Technologies](#technologies)
   *  [Usage](#usage)
   *  [Environment](#environment)
* [Debugging/logging](#debugginglogging)
* [More information](#more-information)

<br>

## Description

This App is part of the program  <b> Lokale Besluiten als Gelinkt Open Data </b> (lblod). It provides user-friendly interface to lookup data using Sparql, accessing that data in both a human as well as a machine readable way.  Based on the mu-semtech microservice architecture for the backend en Emberjs for the frontend.

<br>

## List of Services


| Service  | Repository  |
|---|---|
| identifier  | https://github.com/mu-semtech/mu-identifier  |
| dispatcher  | https://github.com/mu-semtech/mu-dispatcher  |
| database  | https://github.com/mu-semtech/mu-authorization  |
| virtuoso  | https://github.com/tenforce/docker-virtuoso  |
| migrations | https://github.com/mu-semtech/mu-migrations-service |
| resource-labels  | https://github.com/lblod/resource-label-service  |
| cache | https://github.com/mu-semtech/mu-cache |
| delta-notifier | https://github.com/mu-semtech/delta-notifier |
| file | https://github.com/mu-semtech/file-service |
| harvesting-download-url | https://hub.docker.com/r/lblod/download-url-service  |
| harvesting-initiation  | https://github.com/lblod/harvesting-initiation-service |
| harvest-collector | https://github.com/lblod/harvest-collector-service |
| harvesting-import | https://github.com/lblod/harvesting-import-service |
| uri-info | https://github.com/redpencilio/mu-uri-info-service |
| resource | https://github.com/mu-semtech/mu-cl-resources |
| frontend | https://github.com/lblod/frontend-centrale-vindplaats |



<br>

## Setup


#### Clone this repository
```
git clone https://github.com/lblod/app-centrale-vindplaats.git
```


#### Move into the directory
```
cd app-centrale-vindplaats
```


#### Start the system
```
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

<small>It takes a minute before everything is up and running. In case there is an error the first time you launch, just stopping and relaunching docker compose should resolve any issues. </small>

#### Visit the App!

Simply visit http://localhost:80 and you will redirected to the yasgui sparql interface. More info about the frontend in the [frontend section](#frontend) below.

  <br>

## Ingesting data
The app comes with no data, because it depends on external datasources.

  *  [Mandatendatabank (sourced by loket)](https://loket.lokaalbestuur.vlaanderen.be/)
  *  [Leidinggevendendatabank (sourced by loket)](https://loket.lokaalbestuur.vlaanderen.be/)
  *  [lblod-harvester](https://lblod-harvester.lokaalbestuur.vlaanderen.be/)

You can follow the following procedure, for all data sources.

The ingestion should be a one time operation per deployment, and is currenlty semi-automatic for various reasons (mainly related to performance)
The ingestion is disabled by default. It is recommended, for performance, to start only one initial ingest at a time.

To proceed (similar for mandaten and leidinggevenden):
1. make sure the app is up and running. And the migrations have run.
2. In docker-compose.override.yml (preferably) override the following parameters for mandatendatabank-consumer
```
# (...)
  besluiten-consumer:
    environment:
      SYNC_BASE_URL: 'https://dev.harvesting-self-service.lblod.info/' # The endpoint of your choice (see later what to choose)
      DISABLE_INITIAL_SYNC: 'false'
      BATCH_SIZE: 100 # if virtuoso is in prod mode, you can safely beef this up to 500/1000
```
3. `docker-compose up -d besluiten-consumer` should start the ingestion.
  This might take a while if yoh ingest production data.
4. Check the logs, at some point this message should show up
  `Initial sync was success, proceeding in Normal operation mode: ingest deltas`
   or execute in the database:
   ```
   PREFIX adms: <http://www.w3.org/ns/adms#>
   PREFIX task: <http://redpencil.data.gift/vocabularies/tasks/>
   PREFIX dct: <http://purl.org/dc/terms/>
   PREFIX cogs: <http://vocab.deri.ie/cogs#>

   SELECT ?s ?status ?created WHERE {
     ?s a <http://vocab.deri.ie/cogs#Job> ;
       adms:status ?status ;
       task:operation <http://redpencil.data.gift/id/jobs/concept/JobOperation/deltas/consumer/initialSync/besluiten> ;
       dct:created ?created ;
       dct:creator <http://data.lblod.info/services/id/mandatendatabank-consumer> .
    }
    ORDER BY DESC(?created)
   ```
5. `drc restart resource cache` is still needed after the intiial sync.

### Additional notes:
#### Endpoints to choose for ingestion.
On abstract level, all applications which produce deltas provided `delta-producer-*` services set, and talk about the AP-model defined in [mandatendatabank](http://data.vlaanderen.be/doc/applicatieprofiel/mandatendatabank) or [besluit publicatie](https://data.vlaanderen.be/doc/applicatieprofiel/besluit-publicatie/)
In practice, it is going to be loket and harvester apps, and their dev and QA variations.
#### Performance
- The default virtuoso settings might be too weak if you need to ingest the production data. Hence, there is better config, you can take over in your `docker-compose.override.yml`
```
  virtuoso:
    volumes:
      - ./data/db:/data
      - ./config/virtuoso/virtuoso-production.ini:/data/virtuoso.ini
      - ./config/virtuoso/:/opt/virtuoso-scripts
```
#### delta-producer-report-generator
Not all required parameters are provided, since deploy specific, see [report-generator](https://github.com/lblod/delta-producer-report-generator)
#### deliver-email-service
Should have credentials provided, see [deliver-email-service](https://github.com/redpencilio/deliver-email-service)

## Frontend

### Technologies

The frontend is what the user actually interacts with. With the use of our addons you are presented with a sparql interface and when visiting different routes with the corresponding , rdf-friendly, data.
It is build on top of the [Ember.js](https://emberjs.com/) framework. And server side rendered by [Fastboot](#https://ember-fastboot.com/)


### Usage
When you first visit the ```http://localhost:80``` you will be redirected to a sparql interface. This will already have performed a search query that presents you with data from the database. ( Only in case your migrations folder and therefor Triplestore is populated with data ). If you are running the app locally and you want to get more information about a subject then you will have to copy part of the url into your browsers searchbar.


##### Example
 * The results of on the sparql route will probably be displayed like so:
   ```Subject-uri | predicate-uri | object-uri```

 * Let's take an arbitrary subject-uri as an example
```<http://data.lblod.info/id/bestuursorganen/293a6433b88c65f11071c86fff60459cfa80c6623984e9da9757a6e4c648c079>```

 * Trim of the the protocol, subdomain and domain name so you only have the path left
    ```/id/bestuursorganen/293a6433b88c65f11071c86fff60459cfa80c6623984e9da9757a6e4c648c079>```

 *  Inside your searchbar, prepend that path by ``` http://localhost:80``` and hit enter
     ```http://localhost:80/id/bestuursorganen/293a6433b88c65f11071c86fff60459cfa80c6623984e9da9757a6e4c648c079>```


 If info exists about that subject then you should be met by a table with data about that uri, both direct and invers. The [resource-label](https://github.com/lblod/resource-label-service) service automatically looks for labels & description for each uri and displays them if they exists. You can now just simply click through each link that starts with ```http://data.lblod.info/``` to get more information of the clicked uri inside this frontend or click on any other link to get redirected outside it.

### Environment

The frontend service accepts a base url, the default is <b> http://data.lblod.info/ </b>.
An environment variable is <b> required </b>.


 ```
   frontend:
    image: aatauil/frontend-centrale-vindplaats:1.1.0-fastboot
    environment:
      BASE_URL: "http://data.lblod.info/"

 ```

<br>

### Relevant Addons
#### Ember-metis
The frontend uses our [metis](https://github.com/redpencilio/ember-metis) addon to take care of the routes and calls to the coresponding info and labels.

#### Ember-cli-yasgui
The [yasgui](https://github.com/nvdk/ember-cli-yasgui) addon that gives you a sparql interface when visiting ```http://localhost/sparql``` .


#### Ember-fastboot
The ember-fastboot addon makes it possible to render the page in nodejs. The frontend is server by our [fastboot-server container](https://hub.docker.com/r/redpencil/fastboot-app-server).

<br>

### Debugging/logging
The mu-semtech stack also provides a [http-logger](https://github.com/redpencilio/app-http-logger) based on [Kibana](https://www.elastic.co/kibana). You can run this independently from app-centrale-vindplaats. All services inside the docker-compose file of the app-centrale-vindplaats that have the label logging ( the value after that does not really matter ) will be logged by the http-logger. More info on the http-loggers [readme](https://github.com/redpencilio/app-http-logger) file inside the repo

<br>

### More information
If you have any questions about a particular service then you can simply visit that service's repo and read the readme file. These should mostly all be up to date and help a lot in understanding the service. All links are displayed above in de [Service list](#list-of-services)
