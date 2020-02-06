from django.urls import path
from rest_framework_jwt.views import obtain_jwt_token
from rest_auth.views import PasswordResetView, PasswordResetConfirmView
from . import views

urlpatterns = [
    path('signup/', views.CreateAccountView.as_view(), name='create-user'),
    path('login/', obtain_jwt_token, name='login'),
    path('reset-password/', PasswordResetView.as_view(), name='password_reset'),
    path('reset/<uidb64>/<token>/', PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    # path('reset/<uidb64>/<token>/', views.CustomPasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    # path('auth/revoke/', views.logout, name='logout'),
]