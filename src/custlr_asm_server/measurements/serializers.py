from rest_framework import serializers
from .models import Image

class ImageSerializer(serializers.ModelSerializer):
    class Meta:
        model   = Image
        fields  = ["image"]

class MeasurementSerializer(serializers.ModelSerializer):
    class Meta:
        model   = Image
        fields  = ["id", "image", "image_landmark", "chest", "shoulder", "arm_size", "waist", "arm_length", "date_created"]