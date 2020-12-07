FROM alpine:3.12 
<<<<<<< HEAD

# build ffmpeg 4.2.2 from the source code 
# ffmpeg container
RUN apk add ffmpeg 
ENTRYPOINT ["ffmpeg"]
CMD ["@"]
=======
ENV RTMP_URL rtmp://localhost:1935/live/stream
COPY camera-300s.mkv /
COPY docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh
# build ffmpeg 4.2.2 from the source code 
# ffmpeg container
RUN apk add ffmpeg 
CMD /docker-entrypoint.sh
>>>>>>> af5defaf45abbfbc07ce36e54f4a9ee265066bad
