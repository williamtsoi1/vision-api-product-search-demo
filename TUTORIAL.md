# Instructions

## Introduction

This repo shows an end-to-end example on how to use the [Vision API Product Search](https://cloud.google.com/vision/product-search/docs). A high level overview of the solution is provided on the <walkthrough-editor-open-file filePath="vision-api-product-search-demo/README.md">README.md</walkthrough-editor-open-file> file.

Follow the steps in this guide to deploy your own Vision API Product Search solution!

Click the **Start** button to move to the next step.

## Install Nodejs v12

From cloud shell, execute the following to install nodejs v12:

```bash
nvm install 12
nvm use 12
```

Verify that this is installed correctly by executing:

```bash
node -v
```

## Install Terraform v0.14.4

From Cloud Shell, execute the following to install 0.14.4 of Terraform:

```bash
export TERRAFORM_VERSION="0.14.4"
curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    sudo unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip
```

Verify that this is installed correctly by executing:

```bash
terraform -v
```

## Set the `PROJECT_ROOT` environment variable

Execute the following to set an environment variable that will be used throughout the rest of these instructions

```bash
export PROJECT_ROOT=$(pwd)
```

## Create a `variables.json` file in the repository root

Open the <walkthrough-editor-open-file filePath="vision-api-product-search-demo/variables.json.renameMe">variables.json.renameMe</walkthrough-editor-open-file> file.

The file should be in this format, the fields to fill in are quite self-explanatory:

```
{
    "project_id": "PROJECT_PREFIX",
    "billing_account_id": "BILLING_ACCOUNT_ID",
    "region": "GCP_REGION",
    "app_engine_region": "APP_ENGINE_REGION"
}
```

When you have finished editing this file, save a copy of this file as `variables.json`.

_Note: there are two variables for `region` and `app_engine_region`, because sometimes they are not the same. You can get a list of GCP regions by running `gcloud compute regions list`, and you can get a list of App Engine regions by running `gcloud app regions list`._ 

## Deploy the infrastructure 

We will use Terraform to automate the deployment of the infrastructure. Simply execute the following:

```bash
cd $PROJECT_ROOT/terraform
terraform init
terraform plan
```
Double check that the infrastructure to be deployed makes sense, and then execute:

```bash
terraform apply -auto-approve
```

## Generate service account credentials for later use

As part of the deployed infrastructure, a service account and corresponding key has been generated. Execute the following to export the key for later use:

```bash
terraform output -raw vision_product_search_service_account_key | base64 --decode > $PROJECT_ROOT/firestore-migrator/credentials.json
```

## Deploy Firebase Function for image download and processing

Now we will deploy the Firebase Function which will download the required product images for us.

Execute the following to set the project context of the Firebase SDK, so it knows which project to deploy the function into:

```bash
cd $PROJECT_ROOT/firebase
sed -E "s/ADD_YOUR_PROJECT_HERE/$(terraform output -raw -state=$PROJECT_ROOT/terraform/terraform.tfstate project_id)/" .firebaserc.renameMe > .firebaserc
```

Your `.firebaserc` should now look like the following:

```
{
  "projects": {
    "default": "PROJECT_ID"
  }
}
```

Next, install node dependencies:

```bash
cd $PROJECT_ROOT/firebase/functions
npm install
```

Now we're almost ready to deploy, but first we need to configure which Cloud Storage bucket the images should be downloaded into. This bucket was created by Terraform already.

```bash
cd $PROJECT_ROOT/firebase
firebase functions:config:set imagebucket.name="$(terraform output -raw -state=$PROJECT_ROOT/terraform/terraform.tfstate project_id)_images" 
```

Now we can deploy the Firebase Function:

```bash
firebase deploy --only functions
```

## Import CSV data into Firestore

We will use the `firestore-migrator` command line tool to import the product data into a Firestore collection called `products`. We will need to compile and build the tool first:

```bash
cd $PROJECT_ROOT/firestore-migrator
npm install
npm run-script build
npm link
```

Now we can use the `fire-migrate` CLI to import all the records into Firestore, which will then kick off the Firebase Function to download the images into GCS. Note that the import process will take a few minutes, which is normal.

```bash
fire-migrate import $PROJECT_ROOT/data/products_0.csv products
fire-migrate import $PROJECT_ROOT/data/products_1.csv products
fire-migrate import $PROJECT_ROOT/data/products_2.csv products
```

## Deploy Test Harness application

Let's deploy our test harness application

```bash
cd $PROJECT_ROOT/google-product-search-simple-ui
gcloud app deploy --project "$(terraform output -raw -state=$PROJECT_ROOT/terraform/terraform.tfstate project_id)"
```

When the app is successfully deployed, it should be accessible from:

```
http://<PROJECT_ID>ae.uc.r.appspot.com
```

## Process and upload the bulk upload CSV file

We now need to do some processing on the products CSV files (because Vision API requires GCS URIs for the images). So run the following command to generate a new set of CSV files.

```bash
cd $PROJECT_ROOT/data
sed -E "s/http:\/\//gs:\/\/$(terraform output -raw -state=$PROJECT_ROOT/terraform/terraform.tfstate project_id)_images\//" products_0.csv > products_gcs_0.csv
sed -E "s/http:\/\//gs:\/\/$(terraform output -raw -state=$PROJECT_ROOT/terraform/terraform.tfstate project_id)_images\//" products_1.csv > products_gcs_1.csv
sed -E "s/http:\/\//gs:\/\/$(terraform output -raw -state=$PROJECT_ROOT/terraform/terraform.tfstate project_id)_images\//" products_2.csv > products_gcs_2.csv
```

The first few lines of `products_gcs_0.csv` should be something like this:

```csv
image-uri,image-id,product-set-id,product-id,product-category,product-display-name,labels,bounding-poly
gs://<image-bucket>/img.bbystatic.com/BestBuy_US/images/products/4390/43900_sa.jpg,,products,43900,general-v1,Duracell - AAA Batteries (4-Pack),,
gs://<image-bucket>/img.bbystatic.com/BestBuy_US/images/products/4853/48530_sa.jpg,,products,48530,general-v1,Duracell - AA 1.5V CopperTop Batteries (4-Pack),,
gs://<image-bucket>/img.bbystatic.com/BestBuy_US/images/products/1276/127687_sa.jpg,,products,127687,general-v1,Duracell - AA Batteries (8-Pack),,
```

Check that the generated CSV files look fine, and then upload them into the image bucket by running:

```bash
gsutil cp $PROJECT_ROOT/data/products_gcs_* $(terraform output -raw -state=$PROJECT_ROOT/terraform/terraform.tfstate vision_product_search_buckload_bucket_url)
```

## Index the Product Set using the Test Harness App

- Browse to the Test Harness application (`https://<project-id>ae.uc.r.appspot.com`)
- Click on the yellow "Upload service account json file" button, select the service account key which is in `firestore-migrator/credentials.json`
- Choose the appropriate Location (this should be close to the region you've chosen earlier)
- In the "Index images from CSVs" section, click on the + arrow twice to ensure there are three lines available
- For each of the lines, enter the GCS URI for the bulk upload CSV files and click on each "Import" button. The GCS URIs should be:
  ```
  gs://<project-id>_buckload/products_gcs_0.csv
  gs://<project-id>_buckload/products_gcs_1.csv
  gs://<project-id>_buckload/products_gcs_2.csv
  ```

_Note: The indexing will take approximately 15-30 minutes for the operation to be "complete". It can also take potentially another 30-60 minutes for the machine learning model to train in the background._
