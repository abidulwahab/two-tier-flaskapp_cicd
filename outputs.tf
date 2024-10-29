output "control_plane_ip" {
  value = aws_instance.kubeadm_demo_control_plane.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.kubeadm_demo_control_plane.public_ip}:8080"
}

output "worker_nodes_ip" {
  value = join("\n", aws_instance.kubeadm_demo_worker_nodes[*].public_ip)
}
