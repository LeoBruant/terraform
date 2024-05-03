#!/bin/bash

sudo apt install git nodejs -y

git clone https://github.com/LeoBruant/terraform-project && cd terraform-project

npm run build

exit 0
