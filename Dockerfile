# === 第一阶段：构建 Go 二进制 ===
FROM golang:1.26 AS go-builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# 如果入口在根目录，直接 build .；否则改成 ./cmd/xxx
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /out/ds2api .

# === 第二阶段：构建 WebUI（可选） ===
FROM node:20-alpine AS webui-builder
WORKDIR /webui
COPY webui/package*.json ./
RUN npm ci
COPY webui/ .
RUN npm run build

# === 第三阶段：运行时镜像 ===
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app

# 复制 Go 程序
COPY --from=go-builder /out/ds2api .
# 复制预编译的前端（如果生成了 dist）
COPY --from=webui-builder /webui/dist ./webui/dist
# 复制一个默认的 config.json（避免挂载目录问题）
COPY config.json ./config.json

# 入口脚本可选，若需要动态设置环境变量等
EXPOSE 5001
CMD ["./ds2api"]
