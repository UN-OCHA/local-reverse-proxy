Sometimes there are 502 errors for a 'too big header'

To avoid these, create a vhost file in this directory for the name of the base
url of the affected site (e.g. hrinfo.test), containing these lines:

```
proxy_busy_buffers_size 512k;
proxy_buffers 4 512k;
proxy_buffer_size 256k;
```
