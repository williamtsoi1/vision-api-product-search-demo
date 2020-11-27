'use strict';
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const superagent = require('superagent');
const vision = require('@google-cloud/vision');
const client = new vision.ProductSearchClient();

const bucketName = functions.config().imagebucket.name;

exports.downloadImageUploadGCS = functions.firestore.document('products/{productId}').onCreate(async (event) => {
    const productRecord = event.data();
    const productImageUrl = productRecord['image-uri'];
    // grab everything AFTER "//" for the GCS path to ensure unique file name for images
    const fileName = productImageUrl.substring(productImageUrl.lastIndexOf('//') + 2);
    // this only contains the file name
    const fileShortName = productImageUrl.substring(productImageUrl.lastIndexOf('/') + 1);
    const bucket = admin.storage().bucket(bucketName);
    const file = bucket.file(fileName);
    const gcsUri = `gs://${bucketName}/${fileName}`;

    // download image from web and upload to GCS
    await superagent.get(productImageUrl)
            .pipe(file.createWriteStream());
    
    // write upload         
    event.ref.set({
        gcs_uri: gcsUri
    }, {merge: true});
    
    return console.info(`Uploaded file to GCS: ${gcsUri}`);
});
