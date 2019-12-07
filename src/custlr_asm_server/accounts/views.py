from rest_framework import generics, permissions, status
from rest_framework.response import Response
from .models import Account
from .serializers import CreateAccountSerializer, TokenSerializer, LoginSerializer
from django.contrib.auth import authenticate
from rest_framework_jwt.settings import api_settings

# Get the JWT settings
jwt_payload_handler = api_settings.JWT_PAYLOAD_HANDLER
jwt_encode_handler = api_settings.JWT_ENCODE_HANDLER


class CreateAccountView(generics.CreateAPIView):
    permission_classes = [permissions.AllowAny]
    queryset = Account.objects.all()
    serializer_class = CreateAccountSerializer


class LoginView(generics.CreateAPIView):
    permission_classes = (permissions.AllowAny,)
    queryset = Account.objects.all()
    serializer_class = LoginSerializer

    def post(self, request, *args, **kwargs):
        username = request.data.get("username")
        password = request.data.get("password")
        
        if username is "":
            return Response({"error": "Username may not be blank"}, status=status.HTTP_422_UNPROCESSABLE_ENTITY)
        if password is "":
            return Response({"error": "Password may not be blank"}, status=status.HTTP_422_UNPROCESSABLE_ENTITY)
        else:
            user = authenticate(request, username=username, password=password)

        if user is not None:
            serializer = TokenSerializer(data={
                # using drf jwt utility functions to generate a token
                "token": jwt_encode_handler(
                    jwt_payload_handler(user)
                ),
                "message": "Login successful"
                })
            if serializer.is_valid():
                return Response(serializer.data)

        return Response({"error": "Invalid username or password"}, status=status.HTTP_401_UNAUTHORIZED)
