from django.urls import path
from rest_framework_jwt.views import obtain_jwt_token
from . import views

urlpatterns = [
    path('signup/', views.CreateAccountView.as_view(), name='create-user'),
    path('login/', obtain_jwt_token),
    # path('auth/revoke/', views.logout, name='logout'),
]