PROJECT_ID=dss2022-julia-and-vertexai

echo "Purging image folder..."
rm -rf image
echo "done. Copying image content..."
mkdir image
cp -R ../UnitCommitment image/
cp Dockerfile image/
cp requirements.txt image/

echo "done. Start building image..."

gcloud builds submit --project=$PROJECT_ID --config cloudbuild.json image

echo "done."
