if localStorage.getItem("naubino_hiscore")?
  scores = JSON.parse localStorage.getItem("naubino_hiscore")
  console.log scores

head = _.template "<tr><th> <%= name %> </th> <th> <%= points%> </th></tr>"

line = _.template "<tr>
  <td> <%= name %> </td>
  <td> <%= points%> points  </td>
  <td> level <%= level %> </td>
  </tr>"


scores = _(scores).sortBy (s)-> -s.points


#document.querySelector("#highscore_table").insertAdjacentHTML "beforeend", head {name: "Name", points: "Points"}

table_body = document.querySelector(".highscore_table")
for score in scores
  table_body.insertAdjacentHTML "beforeend", line score
