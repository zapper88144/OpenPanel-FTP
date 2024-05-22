"""
ftp.py
"""
from flask_babel import Babel, _ # https://python-babel.github.io/flask-babel/
from flask import Flask, g, session, redirect, request
import re
import os
import mysql.connector
from functools import wraps
import subprocess
from subprocess import getoutput, check_output
import shlex
import importlib
import random
import string

#openadmin
from app import app
from app import login_required_route, log_user_action, query_username_by_id, get_container_port, get_server_ip
from modules.core.webserver import get_config_file_path, get_php_version_preference
from modules.core.config import php_version_for_phpmyadmin_in_containers

