# Google Cloud Platform Vision API Product Search Demo

## Introduction

This repo shows an end-to-end example on how to use the [Vision API Product Search](https://cloud.google.com/vision/product-search/docs).

This feature of Vision API is part of [Google Cloud for retail](https://cloud.google.com/solutions/retail). A retailer can upload their product catalog, which includes images of their products. Customers can then perform image searches on this catalog, and the solution will provide the user with a list of similar products with similarity scores.

Watch [this video](https://www.youtube.com/watch?v=6PLaVc0rc6o&feature=emb_logo&autoplay=1) to see how IKEA uses this solution to enhance their customer experience, so that customers can use a mobile app to interactively construct their shopping list, simply by taking photos of products in the showroom!

## Prerequisites

Here is what you need in order to deploy this solution:
- An active Google Cloud Billing Account
- Terraform (tested on version 0.14.3)
- gcloud SDK (tested on version 319.0.0)
- firebase SDK (tested on version 9.1.0)
- nodejs (tested on version 12.16.2)
- sed command-line tool
- a UNIX bash-compatible shell

## Instructions

### Install the prerequisite software in your environment

TODO: More detailed instructions later. For now, Google is your friend.

### Git clone this repository and set the `PROJECT_ROOT` environment variable

Execute the following to clone a copy of this repository, and also to set an environment variable that will be used throughout the rest of these instructions
```
git clone https://github.com/williamtsoi1/vision-api-product-search-demo.git
cd vision-api-product-search-demo
export PROJECT_ROOT=$(pwd)
```

### Log in to gcloud and firebase SDK

Execute the following, and follow the interactive prompts to login:
```
gcloud auth login
```
```
gcloud auth application-default login
```
```
firebase login
```
### Create a `variables.json` file in the repository root

The file should be in this format, the fields to fill in are quite self-explanatory:

```
{
    "project_id": "PROJECT_PREFIX",
    "billing_account_id": "BILLING_ACCOUNT_ID",
    "region": "GCP_REGION",
    "app_engine_region": "APP_ENGINE_REGION"
}
```

_Note: there are two variables for `region` and `app_engine_region`, because sometimes they are not the same. You can get a list of GCP regions by running `gcloud compute regions list`, and you can get a list of App Engine regions by running `gcloud app regions list`._ 

### Deploy the infrastructure 

We will use Terraform to automate the deployment of the infrastructure. Simply execute the following:

```
cd $PROJECT_ROOT/terraform
terraform init
terraform plan
```
Double check that the infrastructure to be deployed makes sense, and then execute:

```
terraform apply -auto-approve
```

### Generate service account credentials for later use

As part of the deployed infrastructure, a service account and corresponding key has been generated. Execute the following to export the key for later use:

```
terraform output -raw vision_product_search_service_account_key | base64 --decode > ../firestore-migrator/credentials.json
```

### Deploy Firebase Function for image download and processing

Now we will deploy the Firebase Function which will download the required product images for us.

Execute the following to set the project context of the Firebase SDK, so it knows which project to deploy the function into:

```
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

```
cd $PROJECT_ROOT/firebase/functions
npm install
```

Now we're almost ready to deploy, but first we need to configure which Cloud Storage bucket the images should be downloaded into. This bucket was created by Terraform already.

```
cd $PROJECT_ROOT/firebase
firebase functions:config:set imagebucket.name="$(terraform output -raw -state=$PROJECT_ROOT/terraform/terraform.tfstate project_id)_images" 
```

Now we can deploy the Firebase Function:

```
firebase deploy --only functions
```

### Import CSV data into Firestore

We will use the `firestore-migrator` command line tool to import the product data into a Firestore collection called `products`. We will need to compile and build the tool first:

```
cd $PROJECT_ROOT/firestore-migrator
npm install
npm run-script build
sudo npm link
```
Now we can use the `fire-migrate` CLI to import all the records into Firestore, which will then kick off the Firebase Function to download the images into GCS. Note that the import process will take a few minutes, which is normal.

```
fire-migrate import $PROJECT_ROOT/data/products_0.csv products
fire-migrate import $PROJECT_ROOT/data/products_1.csv products
fire-migrate import $PROJECT_ROOT/data/products_2.csv products
```

### Deploy Test Harness application

Let's deploy our test harness application

```
cd $PROJECT_ROOT/google-product-search-simple-ui
gcloud app deploy --project "$(terraform output -raw -state=$PROJECT_ROOT/terraform/terraform.tfstate project_id)"
```

When the app is successfully deployed, it should be accessible from `http://<PROJECT_ID>ae.uc.r.appspot.com`.

### Process and upload the bulk upload CSV file

We now need to do some processing on the products CSV files (because Vision API requires GCS URIs for the images). So run the following command to generate a new set of CSV files.

```
cd $PROJECT_ROOT/data
sed -E "s/http:\/\//gs:\/\/$(terraform output -raw -state=../terraform/terraform.tfstate project_id)_images\//" products_0.csv > products_gcs_0.csv
sed -E "s/http:\/\//gs:\/\/$(terraform output -raw -state=../terraform/terraform.tfstate project_id)_images\//" products_1.csv > products_gcs_1.csv
sed -E "s/http:\/\//gs:\/\/$(terraform output -raw -state=../terraform/terraform.tfstate project_id)_images\//" products_2.csv > products_gcs_2.csv
```

The first few lines of `products_gcs_0.csv` should be something like this:

```csv
image-uri,image-id,product-set-id,product-id,product-category,product-display-name,labels,bounding-poly
gs://<image-bucket>/img.bbystatic.com/BestBuy_US/images/products/4390/43900_sa.jpg,,products,43900,general-v1,Duracell - AAA Batteries (4-Pack),,
gs://<image-bucket>/img.bbystatic.com/BestBuy_US/images/products/4853/48530_sa.jpg,,products,48530,general-v1,Duracell - AA 1.5V CopperTop Batteries (4-Pack),,
gs://<image-bucket>/img.bbystatic.com/BestBuy_US/images/products/1276/127687_sa.jpg,,products,127687,general-v1,Duracell - AA Batteries (8-Pack),,
```

Check that the generated CSV files look fine, and then upload them into the image bucket by running:

```
gsutil cp $PROJECT_ROOT/data/products_gcs_* $(terraform output -raw -state=$PROJECT_ROOT/terraform/terraform.tfstate vision_product_search_buckload_bucket_url)
```

### Index the Product Set using the Test Harness App

- Browse to the Test Harness application (https://<project-id>ae.uc.r.appspot.com)
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
