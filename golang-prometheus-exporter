package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Queue represents the structure of a RabbitMQ queue from the API response.
type Queue struct {
	Name                  string  `json:"name"`
	Vhost                string  `json:"vhost"`
	Messages             float64 `json:"messages"`
	MessagesReady        float64 `json:"messages_ready"`
	MessagesUnacknowledged float64 `json:"messages_unacknowledged"`
}

// Exporter collects metrics from the RabbitMQ HTTP API.
type Exporter struct {
	apiURL    string
	username  string
	password  string
	mutex     sync.Mutex
	metrics   map[string]*prometheus.Desc
}

// NewExporter creates a new Exporter.
func NewExporter(apiURL, username, password string) *Exporter {
	return &Exporter{
		apiURL:   apiURL,
		username: username,
		password: password,
		metrics: map[string]*prometheus.Desc{
			"rabbitmq_individual_queue_messages": prometheus.NewDesc(
				"rabbitmq_individual_queue_messages",
				"Total count of messages in the queue",
				[]string{"host", "vhost", "name"},
				nil,
			),
			"rabbitmq_individual_queue_messages_ready": prometheus.NewDesc(
				"rabbitmq_individual_queue_messages_ready",
				"Count of ready messages in the queue",
				[]string{"host", "vhost", "name"},
				nil,
			),
			"rabbitmq_individual_queue_messages_unacknowledged": prometheus.NewDesc(
				"rabbitmq_individual_queue_messages_unacknowledged",
				"Count of unacknowledged messages in the queue",
				[]string{"host", "vhost", "name"},
				nil,
			),
		},
	}
}

// Describe implements prometheus.Collector.
func (e *Exporter) Describe(ch chan<- *prometheus.Desc) {
	for _, metric := range e.metrics {
		ch <- metric
	}
}

// Collect implements prometheus.Collector.
func (e *Exporter) Collect(ch chan<- prometheus.Metric) {
	e.mutex.Lock()
	defer e.mutex.Unlock()

	queues, err := e.fetchQueues()
	if err != nil {
		log.Printf("Error fetching queues: %v", err)
		return
	}

	host := os.Getenv("RABBITMQ_HOST")
	for _, queue := range queues {
		ch <- prometheus.MustNewConstMetric(
			e.metrics["rabbitmq_individual_queue_messages"],
			prometheus.GaugeValue,
			queue.Messages,
			host, queue.Vhost, queue.Name,
		)
		ch <- prometheus.MustNewConstMetric(
			e.metrics["rabbitmq_individual_queue_messages_ready"],
			prometheus.GaugeValue,
			queue.MessagesReady,
			host, queue.Vhost, queue.Name,
		)
		ch <- prometheus.MustNewConstMetric(
			e.metrics["rabbitmq_individual_queue_messages_unacknowledged"],
			prometheus.GaugeValue,
			queue.MessagesUnacknowledged,
			host, queue.Vhost, queue.Name,
		)
	}
}

// fetchQueues gets the queue data from the RabbitMQ HTTP API.
func (e *Exporter) fetchQueues() ([]Queue, error) {
	req, err := http.NewRequest("GET", e.apiURL+"/api/queues", nil)
	if err != nil {
		return nil, err
	}
	req.SetBasicAuth(e.username, e.password)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, log.Output(2, "Failed to fetch RabbitMQ queues: "+resp.Status)
	}

	var queues []Queue
	if err := json.NewDecoder(resp.Body).Decode(&queues); err != nil {
		return nil, err
	}

	return queues, nil
}

func main() {
	// Read environment variables
	rabbitHost := os.Getenv("RABBITMQ_HOST")
	if rabbitHost == "" {
		rabbitHost = "localhost"
	}
	
	rabbitUser := os.Getenv("RABBITMQ_USER")
	if rabbitUser == "" {
		rabbitUser = "guest"
	}
	
	rabbitPass := os.Getenv("RABBITMQ_PASSWORD")
	if rabbitPass == "" {
		rabbitPass = "guest"
	}

	rabbitURL := "http://" + rabbitHost + ":15672"
	
	exporter := NewExporter(rabbitURL, rabbitUser, rabbitPass)
	prometheus.MustRegister(exporter)

	http.Handle("/metrics", promhttp.Handler())
	log.Printf("Starting server at :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
