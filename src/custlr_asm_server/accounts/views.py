from rest_framework import generics

from accounts.models import Account
from accounts.serializers import AccountSerializer


class AccountListCreate(generics.ListCreateAPIView):
    permission_classes = []
    queryset = Account.objects.all()
    serializer_class = AccountSerializer
