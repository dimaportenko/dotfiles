export const NotificationPlugin = async ({ $ }) => {
  return {
    event: async ({ event }) => {
      // Notify when session completes
      if (event.type === "session.idle") {
        await $`osascript -e 'display notification "Session completed!" with title "OpenCode" sound name "Glass"'`
      }

      // Notify when permission/input is required
      if (event.type === "permission.updated") {
        await $`osascript -e 'display notification "Input required" with title "OpenCode" sound name "Ping"'`
      }

      // Notify on session error
      if (event.type === "session.error") {
        await $`osascript -e 'display notification "Session error occurred" with title "OpenCode" sound name "Basso"'`
      }
    },
  }
}
