defmodule Jiraffe.Avatar.Url do
  @moduledoc """
  Represents Jira Avatar URLs.

  Original Jira object
  ```json
  {
    "16x16": "https://site.com/secure/useravatar?size=xsmall&avatarId=10011",
    "24x24": "https://site.com/secure/useravatar?size=small&avatarId=10011",
    "32x32": "https://site.com/secure/useravatar?size=medium&avatarId=10011",
    "48x48": "https://site.com/secure/useravatar?avatarId=10011"
  }
  ```

  becomes

  ```elixir
  %Jiraffe.Avatar.Url{
    tiny: "https://site.com/secure/useravatar?size=xsmall&avatarId=10011",
    small: "https://site.com/secure/useravatar?size=small&avatarId=10011",
    medium: "https://site.com/secure/useravatar?size=medium&avatarId=10011",
    large: "https://site.com/secure/useravatar?avatarId=10011"
  }
  ```
  """

  @type t() :: %__MODULE__{
          tiny: String.t(),
          small: String.t(),
          medium: String.t(),
          large: String.t()
        }

  defstruct tiny: "",
            small: "",
            medium: "",
            large: ""

  @doc """
  Converts a map (received from Jira API) to `Jiraffe.Avatar.Url` struct.
  """
  @spec new(map()) :: t()
  def new(data) do
    %__MODULE__{
      tiny: Map.get(data, "16x16", ""),
      small: Map.get(data, "24x24", ""),
      medium: Map.get(data, "32x32", ""),
      large: Map.get(data, "48x48", "")
    }
  end
end
