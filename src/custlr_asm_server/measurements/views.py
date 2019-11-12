from django.shortcuts import render
import matlab.engine
from django.http import HttpResponse
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.decorators import parser_classes
from rest_framework.parsers import JSONParser, MultiPartParser
from .serializers import ImageSerializer
from .models import Image

# calls matlab function with image path
def asm_model(image_path):
    eng = matlab.engine.start_matlab()
    eng.cd(r'.\matlab')
    ans = eng.Custlr_ASM_Server_Front_v2(image_path)
    eng.close()
    return ans
        

@api_view(['GET', 'POST'])
@parser_classes([JSONParser, MultiPartParser])
def image_post(request, format=None):
    if(request.FILES):
        data = request.FILES
        image_serializer = ImageSerializer(data=data)
        if image_serializer.is_valid():
            image_serializer.save()
            image_path = '..' + str(image_serializer.data['image'])
            #debug
            print(image_path)
            measurements = asm_model(image_path)
            #debug
            print(measurements)
            return Response(measurements, status=status.HTTP_201_CREATED)
        else:
            return Response(image_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    #test for get request
    if request.method == 'GET':
        image = Image.objects.last()
        image_path = '/media/' + str(image.image)
        html = "<html><body><img src='%s'/></body></html>" % image_path
        return HttpResponse(html)
