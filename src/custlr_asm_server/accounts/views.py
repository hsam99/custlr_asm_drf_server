# handles user sign up


from rest_framework import generics, permissions
from .models import Account
from .serializers import CreateAccountSerializer


# creating a new user account
class CreateAccountView(generics.CreateAPIView):
    permission_classes = [permissions.AllowAny]
    queryset = Account.objects.all()
    serializer_class = CreateAccountSerializer


