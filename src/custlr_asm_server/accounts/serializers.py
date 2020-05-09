# this file specifies the required input parameters in the view function of account creation


import django.contrib.auth.password_validation as validators
from rest_framework import serializers
from .models import Account
from rest_framework.response import Response

class CreateAccountSerializer(serializers.ModelSerializer):

    class Meta:
        model = Account
        fields = ('email', 'username', 'password')

    def validate_password(self, data):
        validators.validate_password(password=data)
        return data
    
    def create(self, validated_data):
        email       = validated_data.pop('email')
        username    = validated_data.pop('username')
        password    = validated_data.pop('password')
        user        = Account.objects.create_user(username=username, email=email, password=password)
        return user
