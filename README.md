# SQL to GraphQL
This is a set of helper scripts used to convert a subset of the Spider Dataset SQL examples to hasura GraphQL examples. 

The whole process involved manual verification of each step, and involved modifications to the databases and schemas.
Since the end result requires manual intervention, and since the end result is already available, this is mostly for reference.

# SqlToPostgres
## prereqs
1. install Postgres
2. install pgloader
3. have a root user on Postgres (`sudo  createuser -s root`)
4. download the spider dataset 
## instructions
run with commanline arg with path to spider dataset ( or add the path to xcode schema)
ex  `swift SqlToPostgres path/to/dataset`


# DownloadSchemas
used to download graphql schemas from hasura. 
## prereqs
1. run SqlToPostgres
2. modify any schemas
## instructions
run DownloadSchema modifying any options, schemas will be downloaded to root of project
ex `swift DownloadSchemas`

# SQLtoGraphQL
used to convert sql queries to graphql given the corresponding hasura schemas. This will create train and dev datasets.
## prereqs
1. run DownloadSchemas
## instructions
run SQLtoGraphQL passing arguments for the spider root folder and the path to save the new dataset
ex `swift SQLtoGraphQL /path/to/spider/root /path/to/newGraphQLdataset`

# VerifyQueryExecution
used to check queries from dataset against the real hasura endpoints. 
## prereqs
1. run SQLtoGraphQL
## instructions
run VerifyQueryExecution passing an argument to the path of the dataset to verify
ex `swift VerifyQueryExecution /path/to/train.json`

# SavePostgres
used to save all postgres databases and hasura metadata
## prereqs
1. run verify all postgres schemas and hasura metadata. 
## instructions
run SavePostgres passing an argument of the path to dump the databases to. ]
ex `swift SavePostgres /path/to/dump/directory`


