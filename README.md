

cd terraform
terraform init
terraform plan
terraform apply -auto-approve
terraform output -raw vision_product_search_service_account_key | base64 --decode > ../firestore-migrator/credentials.json


cd ../firebase
sed -E "s/ADD_YOUR_PROJECT_HERE/$(terraform output -raw -state=../terraform/terraform.tfstate project_id)/" .firebaserc.renameMe > .firebaserc

firebase login

cd functions
npm install
cd ..
firebase functions:config:set imagebucket.name="$(terraform output -raw -state=../terraform/terraform.tfstate project_id)_images" 
firebase deploy --only functions

cd ../firestore-migrator
npm install
npm run-script build
sudo npm link
fire-migrate import ../data/products_0.csv products
fire-migrate import ../data/products_1.csv products
fire-migrate import ../data/products_2.csv products

cd ../google-product-search-simple-ui
gcloud app deploy --project "$(terraform output -raw -state=../terraform/terraform.tfstate project_id)"

cd ../data
sed -E "s/http:\/\//gs:\/\/$(terraform output -raw -state=../terraform/terraform.tfstate project_id)_images\//" products_0.csv > products_gcs_0.csv
sed -E "s/http:\/\//gs:\/\/$(terraform output -raw -state=../terraform/terraform.tfstate project_id)_images\//" products_1.csv > products_gcs_1.csv
sed -E "s/http:\/\//gs:\/\/$(terraform output -raw -state=../terraform/terraform.tfstate project_id)_images\//" products_2.csv > products_gcs_2.csv
gsutil cp products_gcs_* $(terraform output -raw -state=../terraform/terraform.tfstate vision_product_search_buckload_bucket_url)

Browse to the UI
Upload service account key from firestore-migrator directory
Reference uploaded bulkload CSV files
Click import
