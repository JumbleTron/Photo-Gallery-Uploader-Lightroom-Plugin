return {
  metadataFieldsForPhotos = {
    {
      id = "remoteId",
      title = "Remote Photo ID",
      dataType = "string",
      readOnly = true,
    },
    {
      id = "galleryId",
      title = "Gallery ID",
      dataType = "string",
      readOnly = true,
    },
    {
      id = "clientComments",
      title = "Client Comments",
      dataType = "string",
      readOnly = false,
    },
  },

  keywordSynonyms = {
    {
      name = "client-picked",
      synonyms = { "picked", "approved" },
    },
    {
      name = "client-rejected",
      synonyms = { "rejected", "disapproved" },
    },
  },
}
