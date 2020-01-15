from rest_framework import serializers
from accounts.models import Account
from rest_framework.response import Response

class CreateAccountSerializer(serializers.ModelSerializer):

    class Meta:
        model = Account
        fields = ('email', 'username', 'password')
    
    def create(self, validated_data):
        email       = validated_data.pop('email')
        username    = validated_data.pop('username')
        password    = validated_data.pop('password')
        user        = Account.objects.create_user(username=username, email=email, password=password)
        return user

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=45, required=True)
    password = serializers.CharField(max_length=45, required=True)


class TokenSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=255)
    message = serializers.CharField(max_length=255)