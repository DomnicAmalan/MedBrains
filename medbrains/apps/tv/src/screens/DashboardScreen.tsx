import { api } from "@medbrains/api";
import type { HealthResponse } from "@medbrains/types";
import { useQuery } from "@tanstack/react-query";
import React, { useCallback, useState } from "react";
import { StyleSheet, View } from "react-native";
import { ActivityIndicator, Card, Chip, Surface, Text } from "react-native-paper";
import { config } from "../config";
import { useWebSocket } from "../hooks/useWebSocket";

function StatusRow({ label, status }: { label: string; status: string }) {
  const isOk = status === "connected" || status === "ok";
  return (
    <View style={styles.statusRow}>
      <Chip
        icon={isOk ? "check-circle" : "alert-circle"}
        mode="outlined"
        selectedColor={isOk ? "#40c057" : "#fa5252"}
        style={styles.chip}
      >
        {label}
      </Chip>
      <Text variant="bodyLarge" style={styles.statusValue}>
        {status}
      </Text>
    </View>
  );
}

export function DashboardScreen() {
  const { data, isLoading } = useQuery<HealthResponse>({
    queryKey: ["health"],
    queryFn: api.health,
    refetchInterval: 10_000,
  });

  const [wsConnected, setWsConnected] = useState(false);

  const handleWsMessage = useCallback((_data: unknown) => {
    // Handle real-time updates (bed board, queue status) in future iterations
  }, []);

  const { isConnected } = useWebSocket({
    url: config.wsBase,
    onMessage: handleWsMessage,
  });

  if (isConnected !== wsConnected) {
    setWsConnected(isConnected);
  }

  return (
    <View style={styles.container}>
      <Text variant="displaySmall" style={styles.title}>
        MedBrains
      </Text>
      <Text variant="titleMedium" style={styles.subtitle}>
        Hospital Management System — TV Dashboard
      </Text>

      <View style={styles.grid}>
        <Surface style={styles.panel} elevation={2}>
          <Card>
            <Card.Title title="System Health" />
            <Card.Content>
              {isLoading && <ActivityIndicator size="large" />}
              {data && (
                <View style={styles.statusList}>
                  <StatusRow label="Overall" status={data.status} />
                  <StatusRow label="PostgreSQL" status={data.postgres} />
                  <StatusRow label="YottaDB" status={data.yottadb} />
                  <StatusRow
                    label="WebSocket"
                    status={wsConnected ? "connected" : "disconnected"}
                  />
                </View>
              )}
            </Card.Content>
          </Card>
        </Surface>

        <Surface style={styles.panel} elevation={2}>
          <Card>
            <Card.Title title="Bed Board" />
            <Card.Content>
              <Text variant="bodyLarge" style={styles.placeholder}>
                Real-time bed status will appear here via WebSocket.
              </Text>
            </Card.Content>
          </Card>
        </Surface>

        <Surface style={styles.panel} elevation={2}>
          <Card>
            <Card.Title title="Queue Status" />
            <Card.Content>
              <Text variant="bodyLarge" style={styles.placeholder}>
                OPD queue and token display will appear here via WebSocket.
              </Text>
            </Card.Content>
          </Card>
        </Surface>
      </View>

      <Text variant="bodySmall" style={styles.footer}>
        v0.1.0 · Alagappa Group of Institutions
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 48,
    backgroundColor: "#1a1a2e",
  },
  title: {
    color: "#ffffff",
    fontWeight: "bold",
    textAlign: "center",
  },
  subtitle: {
    color: "#aaaaaa",
    textAlign: "center",
    marginBottom: 32,
  },
  grid: {
    flex: 1,
    flexDirection: "row",
    gap: 24,
  },
  panel: {
    flex: 1,
    borderRadius: 12,
    overflow: "hidden",
  },
  statusList: {
    gap: 16,
  },
  statusRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
  },
  chip: {
    minWidth: 140,
  },
  statusValue: {
    opacity: 0.7,
  },
  placeholder: {
    opacity: 0.5,
    fontStyle: "italic",
  },
  footer: {
    color: "#666666",
    textAlign: "center",
    marginTop: 24,
  },
});
