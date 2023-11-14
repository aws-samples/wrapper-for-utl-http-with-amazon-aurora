# UTL_HTTP_UTILITY Wrapper for Amazon Aurora

When migrating from Oracle to Amazon Aurora PostgreSQL-Compatible edition or Amazon RDS for PostgreSQL, one of the key challenges is to implement Hypertext Transfer Protocol (HTTP) callouts from PL/pgSQL, which is natively available in Oracle using UTL_HTTP package, but not in PostgreSQL. With the UTL_HTTP package, we can write PL/SQL programs that communicate with Web (HTTP) servers and for invoking third-party APIs.

In this, we demonstrate how we have solved using the PL/pgSQL custom wrapper functions by converting Oracle UTL_HTTP referenced custom code to Amazon RDS for PostgreSQL and Amazon Aurora PostgreSQL equivalent, deploy and use a wrapper to initiate HTTP requests. 

Important: this application uses various AWS services and there are costs associated with these services after the Free Tier usage - please see the [AWS Pricing page](https://aws.amazon.com/pricing/) for details. You are responsible for any AWS costs incurred. No warranty is implied in this example.

## Solution Overview

Users are offered to send HTTP requests invoking AWS Lambda function from Aurora PostgreSQL database, implemented using Python requests module. Requests is a simple, yet elegant, HTTP library that allows us to send HTTP/1.1 requests extremely easily. 

At a high level, the solution steps are as follows:

    - A new schema is created as “utl_http_utility” in Aurora PostgreSQL and Request and Response type objects are defined as user defined types to represent an HTTP request and response
    
    - Deploy PL/pgSQL custom wrapper functions in Aurora PostgreSQL database for HTTP operations like beginning a request, setting authentication, setting headers, setting params, getting response, reading and writing of lines to and from an HTTP request. These wrapper functions are used to continuously build a JSON object with all the HTTP params (Response Content, URL, Parameters, Custom Headers) and payload
    
    - Install the aws_lambda and aws_commons extension. These extensions enable seamless integration with AWS Lambda functions, offering a more versatile approach to handling API requests and responses.
    
    - The get_response wrapper function is the heart of this solution. This function takes a Request JSON Object as input and invoke an AWS Lambda function. The Lambda function, implemented using Python and the Requests module, is responsible for sending HTTP/1.1 requests to the desired API endpoint.
    
    - AWS Lambda function further does Webservice API Invocation and successfully returns the response and forwards the same back to the Aurora Database in Real Time (Synchronous)

## Requirements

* [Create an AWS account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html) if you do not already have one and log in. The IAM user that you use must have sufficient permissions to make necessary AWS service calls and manage AWS resources.
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed and configured
* [Git Installed](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.CreateInstance.html) instance with latest minor version available for 14 and above or a [RDS for PostgreSQL instance](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_GettingStarted.CreatingConnecting.PostgreSQL.html) with latest minor version available for 14 and above inside a VPC.

## Database Deployment

    - Connect to Aurora PostgreSQL DB Instance
    - Run the file `install.sql`, to create an utility schema and wrapper objects

    ```
    postgres=> \i install.sql
    CREATE EXTENSION
    CREATE SCHEMA
    CREATE TYPE
    CREATE TYPE
    CREATE TABLE
    INSERT 0 1
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE FUNCTION
    CREATE PROCEDURE
    CREATE PROCEDURE
    ```

    - As a next step, once after lambda function deployment is complete, update the parameter table to reflect the lambda function arn details and region

    ```
    update utl_http_utility.utl_http_utility_params
    set lambda_arn = 'arn:aws:lambda:<region>:<account-id>:function:aurora-http-helper',
    lambda_region = '<region>'
    where lambda_key = 'aurora-http-helper'
    ```

## Invoking an AWS Lambda function from an Aurora PostgreSQL DB cluster
Setting up Aurora PostgreSQL to work with Lambda functions is a multi-step process involving AWS Lambda, IAM, VPC, and Aurora PostgreSQL DB cluster. It is expected to follow these guides to setup connectivity between DB cluster and Lambda and further to create aws_lambda extension in DB cluster.

* [Step 1: Configure your Aurora PostgreSQL DB cluster for outbound connections to AWS Lambda](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL-Lambda.html#PostgreSQL-Lambda-network)
* [Step 2: Configure IAM for your Aurora PostgreSQL DB cluster and AWS Lambda](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL-Lambda.html#PostgreSQL-Lambda-access)
* [Step 3: Install the aws_lambda extension for an Aurora PostgreSQL DB cluster](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL-Lambda.html#PostgreSQL-Lambda-install-extension)

Lambda function code depends on additional packages or modules (requests), we should add these dependencies to .zip file with function code. 
The instructions in this section show you how to include your dependencies in your .zip deployment package.

```bash
# Navigate to the project directory containing your lambda_function.py source code file
cd wrapper-for-utl-http-with-amazon-aurora/lambda

#Create a new directory named package into which you will install your dependencies.
mkdir package

#Install dependencies in the package directory. 
pip install --target ./package requests

#Create a .zip file with the installed libraries at the root.
cd package
zip -r ../aurora-http-helper.zip .

#Add the lambda_function.py file to the root of the .zip file
cd ..
zip aurora-http-helper.zip lambda_function.py
```

The following steps shows the deployment of Lambda Function using AWS CLI:

* [Configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and proceed with next steps

```bash
# create IAM role 
aws iam create-role --role-name aurora-utl-http-utility-role --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'

# Attach Role Policy
aws iam attach-role-policy --role-name aurora-utl-http-utility-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# create lambda function, Update the account_id
aws lambda create-function --function-name aurora-http-helper --runtime python3.11 --zip-file fileb://aurora-http-helper.zip  --handler lambda_function.lambda_handler --role arn:aws:iam::<account-id>:role/aurora-utl-http-utility-role
```

## Testing
This anonymous code block demonstrates a sample PL/pgSQL procedure that utilizes various functions from the utl_http_utility package to perform an HTTP POST request with specific headers, payload, and authentication. Additionally, it reads the response and processes it line by line.

For the purpose of testing this module, we can use any valid HTTP endpoint (alternatively, you can use a free HTTP request testing site such as [webhook.site](https://webhook.site/)).
Make sure to update the l_url variable with the valid API URL to invoke.

```
do
$$
declare
    l_req   utl_http_utility.req;
    l_url   CHARACTER VARYING(255) := 'https://webhook.site/a5524281-1cdf-426f-b2bd-c3ce7225ad60';
    l_resp  utl_http_utility.resp;
    l_chunk TEXT;
    l_len   INTEGER := 2000;
    l_text_line TEXT;
begin
    
    SELECT * FROM utl_http_utility.begin_request(l_url,'POST','HTTP/1.1') INTO l_req;
    
    SELECT * FROM utl_http_utility.set_header(l_req,'Content-Type','text/xml') INTO l_req;
    
    SELECT * FROM utl_http_utility.set_header(l_req,'Content-Length','100') INTO l_req;
    
    SELECT * FROM utl_http_utility.write_text(l_req,'Hello, world!') INTO l_req;
    
    SELECT * FROM utl_http_utility.write_line(l_req,'Hello, world in write_line!') INTO l_req;
    
    SELECT * FROM utl_http_utility.write_raw(l_req,'Hello, world in write_raw!') INTO l_req;
    
    SELECT * FROM utl_http_utility.set_transfer_timeout(l_req,60) INTO l_req;
    
    SELECT * FROM utl_http_utility.set_authentication(l_req,'user','password') INTO l_req;
    
    SELECT * FROM utl_http_utility.set_authentication(l_req,'user1','password1') INTO l_req;
    
    SELECT * FROM utl_http_utility.set_params(l_req,'param1','value1') INTO l_req;
    
    SELECT * FROM utl_http_utility.set_params(l_req,'param2','value2') INTO l_req;
    
    raise notice '%', l_req.payload;
    
    SELECT * FROM utl_http_utility.get_response(l_req) INTO l_resp;
    
    CALL utl_http_utility.read_text(l_resp, l_chunk);
    
    raise notice 'read_text chunk:%', l_chunk;
    
    --  utl_http_utility.read_line
    FOREACH l_text_line IN ARRAY regexp_split_to_array(l_chunk, E'\\n') LOOP
        RAISE NOTICE 'Response line: %', l_text_line;
    END LOOP;
    
end;
$$
language plpgsql;

```
Output:

```
Hello, world!



Hello, world in write_line!

\xSGVsbG8sIHdvcmxkIGluIHdyaXRlX3JhdyE=
```

## Cleanup

    - Connect to Aurora PostgreSQL DB Instance
    - Run the file `uninstall.sql`, to drop utility schema and wrapper objects
    - Delete the Lambda Function that was created using AWS CLI

    ```
    aws lambda delete-function --function-name arn:aws:lambda:<region>:<account-id>:function:aurora-http-helper
    ```
    
## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.