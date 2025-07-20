// noinspection JSUnusedGlobalSymbols

import React from 'react';
import { View, Text, TextInput, Pressable, StyleSheet } from 'react-native';

export default function TaskInput() {
  return (
    <View style={styles.container}>
      <Text style={styles.heading}>Enter Your Tasks</Text>
      {/* TODO: Add task input logic here */}
      <TextInput
        style={styles.input}
        placeholder="Task description"
      />
      <Pressable style={styles.button}>
        <Text style={styles.buttonText}>Add Task</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#fff',
  },
  heading: {
    fontSize: 22,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  input: {
    borderColor: '#ccc',
    borderWidth: 1,
    borderRadius: 6,
    padding: 10,
    marginBottom: 16,
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
