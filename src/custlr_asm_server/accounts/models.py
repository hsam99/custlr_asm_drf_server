from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager

class AccountManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, email, username, password=None):
        if not email:
            raise ValueError("Email is required.")
        if not username:
            raise ValueError("Username is required.")
        
        user = self.model(
                email=self.normalize_email(email),
                username=username
        )

        user.set_password(password)
        user.save(using=self._db)
        return user

class Account(AbstractBaseUser):
    email           = models.EmailField(verbose_name='email', unique=True)
    username        = models.CharField(max_length=25, unique=True)
    last_login      = models.DateTimeField(verbose_name='last login', auto_now_add=True)
    date_joined     = models.DateTimeField(verbose_name='date joined', auto_now_add=True)

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email']

    objects = AccountManager()

    class Meta:
        verbose_name = ('account')
        verbose_name_plural = ('accounts')

    def __str__(self):
        return self.username
    

    

