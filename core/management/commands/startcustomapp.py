import os
import shutil

from django.core.management.base import BaseCommand

MODEL_IMPORT = "from django.db import models"
SERIALIZER_IMPORT = "from rest_framework import serializers"
VIEW_IMPORT = "from rest_framework import viewsets"
URL_IMPORTS = "from django.urls import include, path\nfrom rest_framework import routers"
APPS_IMPORT = "from django.apps import AppConfig"

MODEL_TEMPLATE = """
class {model_name}(models.Model):
{fields}

    def __str__(self):
        return self.{first_field}
"""

SERIALIZER_TEMPLATE = """
from {app_import_path}.models import {model_name}

class {model_name}Serializer(serializers.ModelSerializer):
    class Meta:
        model = {model_name}
        fields = '__all__'
"""

VIEWSET_TEMPLATE = """
from {app_import_path}.models import {model_name}
from {app_import_path}.serializers import {model_name}Serializer

class {model_name}ViewSet(viewsets.ModelViewSet):
    queryset = {model_name}.objects.all()
    serializer_class = {model_name}Serializer
"""

URLS_TEMPLATE = """
from django.urls import include, path
from rest_framework import routers
from {app_import_path}.views import {model_name}ViewSet

router = routers.DefaultRouter()
router.register(r'{model_name_lower}', {model_name}ViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
"""

APPS_TEMPLATE = """
from django.apps import AppConfig

class {app_class_name}Config(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "{app_import_path}"
"""

class Command(BaseCommand):
    help = "Create a new Django app with a custom structure and model, serializer, viewset, URL routing, apps.py, and register it in settings and global urls."

    def add_arguments(self, parser):
        parser.add_argument("app_name", type=str, help="Name of the new app")
        parser.add_argument("--src", action="store_true", help="Create the app inside the src directory")

    def handle(self, *args, **kwargs):
        app_name = kwargs["app_name"]
        src_flag = kwargs["src"]
        template_dir = os.path.join(os.getcwd(), "app_template")
        destination_dir = os.path.join(os.getcwd(), "src", app_name) if src_flag else os.path.join(os.getcwd(), app_name)
        app_import_path = f"src.{app_name}" if src_flag else app_name
        app_class_name = f"{app_name.capitalize()}Config"

        if os.path.exists(destination_dir):
            self.stdout.write(self.style.ERROR(f'App directory "{app_name}" already exists!'))
            return

        shutil.copytree(template_dir, destination_dir)
        self.stdout.write(self.style.SUCCESS(f'Successfully created new app "{app_name}" with custom structure'))

        # Create or update apps.py
        apps_path = os.path.join(destination_dir, "apps.py")
        with open(apps_path, "w") as f:
            f.write(APPS_TEMPLATE.format(app_class_name=app_class_name, app_import_path=app_import_path))
        self.stdout.write(self.style.SUCCESS(f'Generated apps.py for "{app_name}"'))

        if input("Do you want to add a model? (y/n): ").strip().lower() != 'y':
            return

        model_name = input("Enter model name: ").strip().title().replace(" ", "")
        fields = []
        while True:
            field = input("Enter field name (or leave blank to finish): ").strip()
            if not field:
                break
            fields.append(f"    {field} = models.CharField(max_length=255, default='')")

        fields_str = "\n".join(fields) or "    pass"
        first_field = fields[0].split()[0] if fields else 'id'

        # Update models.py
        models_path = os.path.join(destination_dir, "models.py")
        with open(models_path, "a") as f:
            if MODEL_IMPORT not in open(models_path).read():
                f.write(f"\n{MODEL_IMPORT}\n")
            f.write(MODEL_TEMPLATE.format(model_name=model_name, fields=fields_str, first_field=first_field))

        # Update serializers.py
        serializers_path = os.path.join(destination_dir, "serializers.py")
        with open(serializers_path, "a") as f:
            if SERIALIZER_IMPORT not in open(serializers_path).read():
                f.write(f"\n{SERIALIZER_IMPORT}\n")
            f.write(SERIALIZER_TEMPLATE.format(app_import_path=app_import_path, model_name=model_name))

        # Update views.py
        views_path = os.path.join(destination_dir, "views.py")
        with open(views_path, "a") as f:
            if VIEW_IMPORT not in open(views_path).read():
                f.write(f"\n{VIEW_IMPORT}\n")
            f.write(VIEWSET_TEMPLATE.format(app_import_path=app_import_path, model_name=model_name))

        # Update urls.py of the app
        urls_path = os.path.join(destination_dir, "urls.py")
        with open(urls_path, "w") as f:
            f.write(URLS_TEMPLATE.format(app_import_path=app_import_path, model_name=model_name, model_name_lower=model_name.lower()))

        # Register app in global urls.py
        project_urls_path = os.path.join(os.getcwd(), "core", "urls.py")
        with open(project_urls_path, "r+") as f:
            content = f.read()
            import_statement = "from django.urls import include, path"
            if import_statement not in content:
                content = f"{import_statement}\n" + content

            include_path = f'path("{app_name}/", include("{app_import_path}.urls"))'
            if include_path not in content:
                if 'urlpatterns = [' in content:
                    content = content.replace('urlpatterns = [', f'urlpatterns = [\n    {include_path},')
                else:
                    content += f"\nurlpatterns = [\n    {include_path},\n]\n"

            f.seek(0)
            f.write(content)
            f.truncate()

        self.stdout.write(self.style.SUCCESS(f'Added "{app_name}" to core/urls.py'))

        # Register app in settings/base.py
        settings_path = os.path.join(os.getcwd(), "core", "settings", "base.py")
        with open(settings_path, "r+") as f:
            content = f.read()
            if 'LOCAL_APPS = [' not in content:
                content += "\nLOCAL_APPS = []\n"

            if f'"{app_import_path}"' not in content:
                content = content.replace('LOCAL_APPS = [', f'LOCAL_APPS = [\n    "{app_import_path}",')

            f.seek(0)
            f.write(content)
            f.truncate()

        self.stdout.write(self.style.SUCCESS(f'App "{app_import_path}" added to LOCAL_APPS in base.py'))
        self.stdout.write(self.style.SUCCESS(f"Model '{model_name}' and associated components created with proper imports, apps.py generated, and app registered successfully."))
