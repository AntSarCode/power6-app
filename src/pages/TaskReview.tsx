// noinspection JSUnusedGlobalSymbols

import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, Pressable, Alert, StyleSheet } from 'react-native';
import { uploadTasks } from '../services/api';

interface Task {
  id: number;
  text: string;
  rank: number;
  completed: boolean;
}

export default function TaskReview() {
  const [tasks, setTasks] = useState<Task[]>([]);

  useEffect(() => {
    const stored = localStorage.getItem('power6_tasks');
    if (stored) {
      setTasks(JSON.parse(stored));
    } else {
      const baseURL = process.env.API_BASE_URL || 'http://localhost:8000';

      fetch(`${baseURL}/tasks/today`)
        .then(res => res.ok ? res.json() : [])
        .then(data => {
          if (Array.isArray(data) && data.length > 0) {
            setTasks(data);
            localStorage.setItem('power6_tasks', JSON.stringify(data));
          }
        })
        .catch(err => console.error('Failed to fetch tasks from backend:', err));
    }
  }, []);

  const toggleComplete = (id: number) => {
    const updated = tasks.map((task) =>
      task.id === id ? { ...task, completed: !task.completed } : task
    );
    setTasks(updated);
    localStorage.setItem('power6_tasks', JSON.stringify(updated));
  };

  const handleFinalize = async () => {
    const today = new Date().toISOString().split('T')[0];
    localStorage.setItem(`history_${today}`, JSON.stringify(tasks));

    const allCompleted = tasks.length === 6 && tasks.every((t) => t.completed);
    const currentStreak = Number(localStorage.getItem('streak') || 0);
    const lastCompleted = localStorage.getItem('last_completed_day');

    if (allCompleted) {
      const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
      if (lastCompleted === yesterday) {
        localStorage.setItem('streak', String(currentStreak + 1));
      } else {
        localStorage.setItem('streak', '1');
      }
      localStorage.setItem('last_completed_day', today);
    } else {
      localStorage.setItem('streak', '0');
    }

    try {
      await uploadTasks(tasks);
    } catch (err) {
      console.error('Upload failed:', err);
    }

    localStorage.removeItem('power6_tasks');
    setTasks([]);
    Alert.alert(
      'Power6',
      allCompleted ? 'Perfect day! Streak updated.' : 'Tasks stored. Incomplete day.'
    );
  };

  return (
    <View style={styles.container}>
      <Text style={styles.heading}>Review & Complete Tasks</Text>

      {tasks.length === 0 ? (
        <Text style={styles.emptyText}>
          No tasks available. Add tasks on the Task Input screen first.
        </Text>
      ) : (
        <ScrollView style={styles.taskList}>
          {tasks.map((task) => (
            <Pressable
              key={task.id}
              onPress={() => toggleComplete(task.id)}
              style={styles.taskItem}
            >
              <Text
                style={[
                  styles.taskText,
                  task.completed && styles.completedText,
                ]}
              >
                ✅ Rank {task.rank}: {task.text}
              </Text>
            </Pressable>
          ))}
        </ScrollView>
      )}

      {tasks.length > 0 && (
        <Pressable style={styles.button} onPress={handleFinalize}>
          <Text style={styles.buttonText}>Finalize Review</Text>
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 20,
    flex: 1,
    backgroundColor: '#fff',
  },
  heading: {
    fontSize: 22,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  emptyText: {
    fontSize: 16,
    color: '#666',
  },
  taskList: {
    marginBottom: 20,
  },
  taskItem: {
    paddingVertical: 10,
    borderBottomColor: '#ccc',
    borderBottomWidth: 1,
  },
  taskText: {
    fontSize: 16,
  },
  completedText: {
    textDecorationLine: 'line-through',
    color: '#777',
  },
  button: {
    backgroundColor: '#007aff',
    paddingVertical: 12,
    borderRadius: 6,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
