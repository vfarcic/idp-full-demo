package handlers

import (
	"context"
	"log/slog"
	"net/http"
	"os"

	"github.com/jackc/pgx/v5"

	"github.com/gin-gonic/gin"
)

type Video struct {
	ID    string `json:"id"`
	Title string `json:"title"`
}

func getConn() *pgx.Conn {
	url := os.Getenv("DB_URI")
	conn, err := pgx.Connect(context.Background(), url)
	if err != nil {
		slog.Error("Failed to parse DB_URL", "error", err)
		return nil
	}
	return conn
}

func VideosGetHandler(ctx *gin.Context) {
	slog.Debug("Handling request", "URI", ctx.Request.RequestURI)
	var videos []Video
	conn := getConn()
	if conn == nil {
		return
	}
	defer conn.Close(context.Background())
	rows, err := conn.Query(context.Background(), "SELECT id, title FROM videos")
	if err != nil {
		ctx.String(http.StatusInternalServerError, err.Error())
		return
	}
	defer rows.Close()
	for rows.Next() {
		var video Video
		err := rows.Scan(&video.ID, &video.Title)
		if err != nil {
			ctx.String(http.StatusInternalServerError, err.Error())
			return
		}
		videos = append(videos, video)
	}
	ctx.JSON(http.StatusOK, videos)
}

func VideoPostHandler(ctx *gin.Context) {
	slog.Debug("Handling request", "URI", ctx.Request.RequestURI)
	id := ctx.Query("id")
	if len(id) == 0 {
		ctx.String(http.StatusBadRequest, "id is empty")
		return
	}
	title := ctx.Query("title")
	if len(title) == 0 {
		ctx.String(http.StatusBadRequest, "title is empty")
		return
	}
	video := &Video{
		ID:    id,
		Title: title,
	}
	conn := getConn()
	if conn == nil {
		return
	}
	defer conn.Close(context.Background())
	_, err := conn.Exec(context.Background(), "INSERT INTO videos(id, title) VALUES ($1, $2)", video.ID, video.Title)
	if err != nil {
		ctx.String(http.StatusInternalServerError, err.Error())
		return
	}
}
