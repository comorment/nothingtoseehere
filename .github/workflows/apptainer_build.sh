name: apptainer

on:
  push:
    branches:
      - 'main'
    tags:
      - "v*.*.*"

jobs:
  build-apptainer-container:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    name: Pull Apptainer Container
    steps:
      - name: Check out code for the container builds
        uses: actions/checkout@v4
      - name: Docker meta 
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: |
            ghcr.io/${{ github.repository_owner }}/nothingtoseehere            
          tags: |
            type=semver,pattern={{version}}
            type=ref,event=branch
            type=sha
            type=raw,value=latest,enable={{is_default_branch}}
      - name: Pull and push Singularity container
        run: |
          tags="${{ steps.meta.outputs.tags }}"
          tags_array=
          old_ifs="$IFS"
          IFS=$'\n'
          for tag in $tags; do
              tags_array="$tags_array $tag"
          done
          IFS="$old_ifs"
          echo ${{ secrets.GITHUB_TOKEN }} | oras login --username ${{ github.repository_owner }} --password-stdin ghcr.io
          for tag in $tags_array; do
            echo "processing tag: $tag"
            docker run --platform=linux/amd64 --rm --privileged -v $(pwd):/work kaczmarj/apptainer build nothingtoseehere.sif docker://"$tag"
            # singularity pull nothingtoseehere.sif docker://"$tag"
            # oras push "$tag" --artifact-type application/vnd.acme.rocket.config nothingtoseehere.sif
            rm nothingtoseehere.sif
          done
        shell: sh