<!--
  Knowledge base source for LLM endpoint-routing embeddings.

  Format rules (parsed by embed_kb.sh — keep entries to this shape):
    - Each entry starts with a "## " heading containing the endpoint path.
    - Directly below it, one bullet per field, each on a single line (no
      multi-line values):
        - Method: <HTTP verb>
        - Description: <free text>
        - Examples: <phrase>; <phrase>; <phrase>          (semicolon separated)
        - Params: <name> (<type>, required|optional, <in>): <description>
          (repeat the "- Params:" line once per parameter; omit entirely if none)
-->

## /v2/device/{id}
- Method: GET
- Description: Retrieve full details for a single device by its numeric ID. Returns device identity and display names, online/offline status, approval status, network info (IP addresses, MAC addresses, DNS name, NetBIOS name), assigned owner, parent device, organization, location, node class, role, policies, backup usage statistics, backup bandwidth throttle settings, warranty dates, maintenance status, custom tags, and user-defined data.
- Examples: get device details; look up a device by ID; fetch information about a specific machine; show me a device's status and owner; find a device's IP address; what organization does this device belong to; is this device online or offline; get backup usage for a device; show device warranty information; what policy is assigned to this device; get maintenance status for a machine; find the assigned technician for a device
- Params: id (integer, required, path): Numeric device ID
