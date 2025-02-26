"""
Module-level constants for base configuration.

This module defines the base configuration constants and settings for the Django project.
"""

import os

from core.config.cors import *
from core.env import BASE_DIR
from core.env import config

SECRET_KEY="django-insecure-h+604yp060*j43ss8ygvlkbt+os*o!3i$m-6wf6=51u+#t6iz+"

"""
Third-party applications used in the project.
"""
THIRD_PARTY_APPS = [
    "rest_framework",
    "corsheaders",
    "drf_yasg",
]

"""
Local applications specific to this Django project.
"""
LOCAL_APPS = [
    "core"]


"""
Combined list of installed applications.
"""
INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    *LOCAL_APPS,
    *THIRD_PARTY_APPS,
]


"""
Middleware stack for request/response processing.
"""
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

"""
URL configuration for the project.
"""
ROOT_URLCONF = "core.urls"

"""
Template engine configuration.
"""
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [
            os.path.join(BASE_DIR, "app/email_templates/templates"),
        ],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

"""
WSGI application configuration.
"""
WSGI_APPLICATION = "core.wsgi.application"

"""
Password validation configuration.
"""
AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]

"""
Database configuration.
"""
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql_psycopg2",
        "NAME": config("DB_NAME"),
        "USER": config("DB_USER"),
        "PASSWORD": config("DB_PASSWORD"),
        "HOST": config("DB_HOST"),
        "PORT": config("DB_PORT"),
    }
}



"""
Internationalization and localization settings.
"""
LANGUAGE_CODE = "en-us"
TIME_ZONE = "Africa/Tunis"
USE_TZ = True
USE_I18N = True

"""
Static files (CSS, JavaScript, Images) serving configuration.
"""
STATIC_URL = "/static/"
STATIC_ROOT = os.path.join(BASE_DIR, "static/")


"""
Default primary key field type configuration.
"""
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

"""
Media files (uploads) configuration.
"""
MEDIA_ROOT = os.path.join(BASE_DIR, "media")
MEDIA_URL = "/media/"
