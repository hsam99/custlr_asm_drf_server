from django.urls import path
from . import views

urlpatterns = [
    path('signup/', views.CreateAccountView.as_view(), name='create-user'),
    path('login/', views.LoginView.as_view(), name="authenticate-user"),
    # path('auth/revoke/', views.logout, name='logout'),
]