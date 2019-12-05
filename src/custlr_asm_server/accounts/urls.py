from django.urls import path
from . import views

urlpatterns = [
    path('', views.AccountListCreate.as_view(), name='create-user'),
    # path('auth/', views.authenticate, name="authenticate-user"),
    # path('auth/refresh/', views.refresh_token, name='refresh-token'),
    # path('auth/revoke/', views.logout, name='logout')
]