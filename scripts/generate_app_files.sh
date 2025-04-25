#!/bin/bash

# Script to generate Django app files without requiring Django to be running

# Template strings
MODEL_IMPORT="from django.db import models"
SERIALIZER_IMPORT="from rest_framework import serializers"
VIEW_IMPORT="from rest_framework import viewsets"
URL_IMPORTS="from django.urls import include, path\nfrom rest_framework import routers"
APPS_IMPORT="from django.apps import AppConfig"

MODEL_TEMPLATE='
class %s(models.Model):
%s

    def __str__(self):
        return self.%s
'

SERIALIZER_TEMPLATE='
from %s.models import %s

class %sSerializer(serializers.ModelSerializer):
    class Meta:
        model = %s
        fields = "__all__"
'

VIEWSET_TEMPLATE='
from %s.models import %s
from %s.serializers import %sSerializer

class %sViewSet(viewsets.ModelViewSet):
    queryset = %s.objects.all()
    serializer_class = %sSerializer
'

URLS_TEMPLATE='
from django.urls import include, path
from rest_framework import routers
%s

router = routers.DefaultRouter()
%s

urlpatterns = [
    path("", include(router.urls)),
]
'

APPS_TEMPLATE='
from django.apps import AppConfig

class %sConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "%s"
'

# Check arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 app_name 'model1:field1,field2;model2:field1,field2'"
    exit 1
fi

app_name="$1"
models_data="$2"
src_flag=true
destination_dir=""
app_import_path=""

# Determine app directory and import path
if [ "$src_flag" = true ]; then
    destination_dir="/code/src/$app_name"
    app_import_path="src.$app_name"
else
    destination_dir="/code/$app_name"
    app_import_path="$app_name"
fi

app_class_name="$(tr '[:lower:]' '[:upper:]' <<< ${app_name:0:1})${app_name:1}"

echo "Creating app directory structure: $destination_dir"
mkdir -p "$destination_dir"

# Create __init__.py
touch "$destination_dir/__init__.py"

# Create empty base files
for file in models.py serializers.py views.py; do
    echo -e "# ${app_name} $file\n" > "$destination_dir/$file"
done

# Create apps.py
echo -e "$(printf "$APPS_TEMPLATE" "$app_class_name" "$app_import_path")" > "$destination_dir/apps.py"

# Process models and fields
model_imports=""
viewset_imports=""
router_registrations=""

IFS=';' read -ra MODEL_ENTRIES <<< "$models_data"
for model_entry in "${MODEL_ENTRIES[@]}"; do
    IFS=':' read -r model_name fields <<< "$model_entry"
    
    # Clean up model name (title case, remove spaces)
    model_name="$(tr '[:lower:]' '[:upper:]' <<< ${model_name:0:1})${model_name:1}"
    model_name="${model_name// /}"
    
    # Process fields
    IFS=',' read -ra FIELD_LIST <<< "$fields"
    fields_str=""
    first_field=""
    
    for field in "${FIELD_LIST[@]}"; do
        if [ -z "$first_field" ]; then
            first_field="$field"
        fi
        fields_str="${fields_str}    ${field} = models.CharField(max_length=255, default='')\n"
    done
    
    if [ -z "$fields_str" ]; then
        fields_str="    pass"
        first_field="id"
    fi
    
    # Update models.py
    if ! grep -q "$MODEL_IMPORT" "$destination_dir/models.py"; then
        echo -e "$MODEL_IMPORT" >> "$destination_dir/models.py"
    fi
    echo -e "$(printf "$MODEL_TEMPLATE" "$model_name" "$fields_str" "$first_field")" >> "$destination_dir/models.py"
    
    # Update serializers.py
    if ! grep -q "$SERIALIZER_IMPORT" "$destination_dir/serializers.py"; then
        echo -e "$SERIALIZER_IMPORT" >> "$destination_dir/serializers.py"
    fi
    echo -e "$(printf "$SERIALIZER_TEMPLATE" "$app_import_path" "$model_name" "$model_name" "$model_name")" >> "$destination_dir/serializers.py"
    
    # Update views.py
    if ! grep -q "$VIEW_IMPORT" "$destination_dir/views.py"; then
        echo -e "$VIEW_IMPORT" >> "$destination_dir/views.py"
    fi
    echo -e "$(printf "$VIEWSET_TEMPLATE" "$app_import_path" "$model_name" "$app_import_path" "$model_name" "$model_name" "$model_name" "$model_name")" >> "$destination_dir/views.py"
    
    # Build viewset imports for urls.py
    viewset_imports="${viewset_imports}from ${app_import_path}.views import ${model_name}ViewSet\n"
    router_registrations="${router_registrations}router.register(r'${model_name,,}', ${model_name}ViewSet)\n"
done

# Create urls.py
echo -e "$(printf "$URLS_TEMPLATE" "$viewset_imports" "$router_registrations")" > "$destination_dir/urls.py"

# Register app in global urls.py
project_urls_path="/code/core/urls.py"
if [ -f "$project_urls_path" ]; then
    echo "Updating project URLs in $project_urls_path"
    
    # Create temp file
    tmp_file=$(mktemp)
    
    # Check if import is present
    if ! grep -q "from django.urls import include, path" "$project_urls_path"; then
        echo 'from django.urls import include, path' > "$tmp_file"
        cat "$project_urls_path" >> "$tmp_file"
        mv "$tmp_file" "$project_urls_path"
    fi
    
    # Add URL pattern if not present
    include_path="path(\\\"${app_name}/\\\", include(\\\"${app_import_path}.urls\\\"))"
    if ! grep -q "$include_path" "$project_urls_path"; then
        # Use a different delimiter for sed (| instead of /)
        if grep -q "urlpatterns = \[" "$project_urls_path"; then
            # Using # as delimiter instead of / to avoid escaping issues
            sed "s#urlpatterns = \[#urlpatterns = \[\n    $include_path,#" "$project_urls_path" > "$tmp_file"
            mv "$tmp_file" "$project_urls_path"
        else
            echo -e "\nurlpatterns = [\n    $include_path,\n]\n" >> "$project_urls_path"
        fi
    fi
fi

# Register app in settings/base.py
settings_path="/code/core/settings/base.py"
if [ -f "$settings_path" ]; then
    echo "Updating settings in $settings_path"
    
    # Create temp file
    tmp_file=$(mktemp)
    
    # Add LOCAL_APPS if not present
    if ! grep -q "LOCAL_APPS = \[" "$settings_path"; then
        echo -e "\nLOCAL_APPS = []\n" >> "$settings_path"
    fi
    
    # Add app to LOCAL_APPS if not present
    app_declaration="\"${app_import_path}\""
    if ! grep -q "$app_declaration" "$settings_path"; then
        sed "s/LOCAL_APPS = \[/LOCAL_APPS = \[\n    $app_declaration,/" "$settings_path" > "$tmp_file"
        mv "$tmp_file" "$settings_path"
    fi
fi

echo "Successfully created Django app with models, serializers, views, and URLs."
echo "App has been registered in project URLs and settings."