import django.contrib.auth.password_validation as validators
from rest_framework import serializers
from accounts.models import Account
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

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=45, required=True)
    password = serializers.CharField(max_length=45, required=True)


class TokenSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=255)
    message = serializers.CharField(max_length=255)


# class PasswordResetConfirmSerializer(serializers.Serializer):
#     """
#     Serializer for requesting a password reset e-mail.
#     """
#     new_password1 = serializers.CharField(max_length=128)
#     new_password2 = serializers.CharField(max_length=128)
#     uid = serializers.CharField()
#     token = serializers.CharField()



#     def custom_validation(self, attrs):
#         pass

#     def validate(self, attrs):
#         self._errors = {}

#         # Decode the uidb64 to uid to get User object
#         try:
#             uid = force_text(uid_decoder(attrs['uid']))
#             self.user = UserModel._default_manager.get(pk=uid)
#         except (TypeError, ValueError, OverflowError, UserModel.DoesNotExist):
#             raise ValidationError({'uid': ['Invalid value']})

#         self.custom_validation(attrs)
#         # Construct SetPasswordForm instance
#         self.set_password_form = self.set_password_form_class(
#             user=self.user, data=attrs
#         )
#         if not self.set_password_form.is_valid():
#             raise serializers.ValidationError(self.set_password_form.errors)
#         if not default_token_generator.check_token(self.user, attrs['token']):
#             raise ValidationError({'token': ['Invalid value']})

#         return attrs

#     def save(self):
#         return self.set_password_form.save()