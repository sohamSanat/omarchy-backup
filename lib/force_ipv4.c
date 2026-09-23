#define _GNU_SOURCE
#include <stddef.h>
#include <dlfcn.h>
#include <sys/socket.h>
#include <netdb.h>
#include <string.h>
#include <arpa/inet.h>
#include <stdlib.h>

int getaddrinfo(const char *node, const char *service, const struct addrinfo *hints, struct addrinfo **res) {
    static int (*real_getaddrinfo)(const char *, const char *, const struct addrinfo *, struct addrinfo **) = NULL;
    if (!real_getaddrinfo) {
        real_getaddrinfo = dlsym(RTLD_NEXT, "getaddrinfo");
    }

    if (node && strstr(node, "crates.io")) {
        struct addrinfo *ai = calloc(1, sizeof(struct addrinfo));
        struct sockaddr_in *sa = calloc(1, sizeof(struct sockaddr_in));
        sa->sin_family = AF_INET;
        sa->sin_port = htons(service ? atoi(service) : 443);
        inet_pton(AF_INET, "151.101.194.137", &sa->sin_addr);

        ai->ai_family = AF_INET;
        ai->ai_socktype = hints ? hints->ai_socktype : SOCK_STREAM;
        ai->ai_protocol = hints ? hints->ai_protocol : IPPROTO_TCP;
        ai->ai_addrlen = sizeof(struct sockaddr_in);
        ai->ai_addr = (struct sockaddr *)sa;
        ai->ai_canonname = strdup(node);
        ai->ai_next = NULL;

        *res = ai;
        return 0;
    }

    struct addrinfo modified_hints;
    if (hints) {
        modified_hints = *hints;
    } else {
        __builtin_memset(&modified_hints, 0, sizeof(modified_hints));
    }
    modified_hints.ai_family = AF_INET;
    return real_getaddrinfo(node, service, &modified_hints, res);
}
